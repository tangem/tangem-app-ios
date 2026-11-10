//
//  CollectiblesPendingPurchaseBannersViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemCollectibles
import TangemFoundation
import TangemLocalization
import TangemUI

@MainActor
final class CollectiblesPendingPurchaseBannersViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any CollectiblesPendingPurchaseProvider
    private let machineProvider: any CollectiblesMachineProvider
    private let isDelivered: @MainActor (String) -> Bool
    private let openUnfinishedPurchase: @MainActor (CollectiblesPendingPurchase, CollectiblesMachine) -> Void
    private let delayProvider: any PollDelayProvider

    private var purchases: [CollectiblesPendingPurchase] = []
    private var loadTask: Task<Void, Never>?
    private var pollTask: Task<Void, Error>?
    private var openPackTask: Task<Void, Never>?
    private var bannerIDToOpenAfterSheet: String?

    // MARK: - Publishers

    @Published private(set) var banners: [Banner] = []
    @Published private(set) var openingBannerID: String?
    @Published var sheet: Sheet?

    // MARK: - Init

    init(
        provider: any CollectiblesPendingPurchaseProvider,
        machineProvider: any CollectiblesMachineProvider,
        isDelivered: @escaping @MainActor (String) -> Bool,
        openUnfinishedPurchase: @escaping @MainActor (CollectiblesPendingPurchase, CollectiblesMachine) -> Void,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.provider = provider
        self.machineProvider = machineProvider
        self.isDelivered = isDelivered
        self.openUnfinishedPurchase = openUnfinishedPurchase
        self.delayProvider = delayProvider
    }

    deinit {
        pollTask?.cancel()
        openPackTask?.cancel()
    }

    // MARK: - Methods

    func load() async {
        await startLoading().value
    }

    func openPack(bannerID: String) {
        guard openPackTask == nil, let purchase = purchases.first(where: { $0.txID == bannerID }) else {
            return
        }

        let machineID = purchase.machineID

        openingBannerID = bannerID
        openPackTask = Task { [weak self, machineProvider] in
            defer {
                self?.openingBannerID = nil
                self?.openPackTask = nil
            }

            do {
                let machine = try await machineProvider.load(id: machineID)
                try Task.checkCancellation()
                self?.openUnfinishedPurchase(purchase, machine)
            } catch {
                guard !error.isCancellationError else { return }

                CollectiblesLogger.error("Collectibles machine \(machineID) failed to load for the unfinished purchase", error: error)
                Toast(view: WarningToast(text: Localization.commonSomethingWentWrong))
                    .present(layout: .top(padding: Constants.toastPadding), type: .temporary())
            }
        }
    }

    func presentSheetIfPurchaseUnfinished() -> Bool {
        guard openPackTask == nil else {
            return true
        }

        if let unopenedPack = banners.first(where: { $0.kind == .packToOpen }) {
            sheet = .packUnopened(bannerID: unopenedPack.id)
            return true
        }

        guard banners.contains(where: { $0.kind == .paymentInProgress }) else {
            return false
        }

        sheet = .paymentInProgress
        return true
    }

    func openPackFromSheet() {
        guard case .packUnopened(let bannerID) = sheet else { return }

        bannerIDToOpenAfterSheet = bannerID
        sheet = nil
    }

    func closeSheet() {
        sheet = nil
    }

    func sheetDidDismiss() {
        guard let bannerID = bannerIDToOpenAfterSheet else { return }

        bannerIDToOpenAfterSheet = nil
        openPack(bannerID: bannerID)
    }
}

// MARK: - Private logic

private extension CollectiblesPendingPurchaseBannersViewModel {
    @discardableResult
    func startLoading() -> Task<Void, Never> {
        loadTask?.cancel()

        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            await loadPurchases()

            guard !Task.isCancelled else { return }

            loadTask = nil
        }
        loadTask = task

        return task
    }

    func loadPurchases() async {
        do {
            let loadedPurchases = try await provider.load()
            try Task.checkCancellation()

            purchases = loadedPurchases
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }

            if !error.isCancellationError {
                CollectiblesLogger.error("Collectibles pending purchases failed to load", error: error)
            }
        }

        updateBanners()
    }

    func updateBanners() {
        banners = purchases
            .filter { !isDelivered($0.txID) }
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap { purchase in
                Self.kind(of: purchase.status).map { Banner(id: purchase.txID, kind: $0) }
            }

        schedulePolling()
    }

    func schedulePolling() {
        pollTask?.cancel()
        pollTask = nil

        guard banners.contains(where: { $0.kind == .paymentInProgress }) else {
            return
        }

        pollTask = Task { [weak self, delayProvider] in
            try await delayProvider.wait(for: Constants.pollInterval)
            self?.startLoading()
        }
    }

    static func kind(of status: CollectiblesPurchaseStatus) -> Banner.Kind? {
        switch status {
        case .created, .waitingTxHash, .purchaseTxHash, .waitingForPayment:
            .paymentInProgress
        case .packPurchased, .packOpened, .unknown:
            .packToOpen
        // [REDACTED_TODO_COMMENT]
        case .packOpeningError:
            nil
        case .expired, .refunded, .autoBuybacked, .nftReceived, .manuallyBuybacked, .paused:
            nil
        }
    }
}

// MARK: - Constants

private extension CollectiblesPendingPurchaseBannersViewModel {
    enum Constants {
        static let pollInterval: TimeInterval = 5
        static let toastPadding: CGFloat = 14
    }
}

// MARK: - Banner

extension CollectiblesPendingPurchaseBannersViewModel {
    struct Banner: Identifiable, Equatable {
        let id: String
        let kind: Kind

        enum Kind: Equatable {
            case paymentInProgress
            case packToOpen
        }
    }

    enum Sheet: Identifiable, Equatable {
        case paymentInProgress
        case packUnopened(bannerID: String)

        var id: String {
            switch self {
            case .paymentInProgress: "paymentInProgress"
            case .packUnopened(let bannerID): "packUnopened-\(bannerID)"
            }
        }
    }
}
