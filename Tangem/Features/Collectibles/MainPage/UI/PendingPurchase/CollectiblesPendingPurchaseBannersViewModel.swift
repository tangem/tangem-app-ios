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

@MainActor
final class CollectiblesPendingPurchaseBannersViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any CollectiblesPendingPurchaseProvider
    private let isDelivered: @MainActor (String) -> Bool
    private let delayProvider: any PollDelayProvider

    private var purchases: [CollectiblesPendingPurchase] = []
    private var loadTask: Task<Void, Never>?
    private var pollTask: Task<Void, Error>?

    // MARK: - Publishers

    @Published private(set) var banners: [Banner] = []

    // MARK: - Init

    init(
        provider: any CollectiblesPendingPurchaseProvider,
        isDelivered: @escaping @MainActor (String) -> Bool,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.provider = provider
        self.isDelivered = isDelivered
        self.delayProvider = delayProvider
    }

    deinit {
        pollTask?.cancel()
    }

    // MARK: - Methods

    func load() async {
        await startLoading().value
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
}
