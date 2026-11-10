//
//  CollectiblesMachineViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization

@MainActor
final class CollectiblesMachineViewModel: ObservableObject {
    // MARK: - Properties

    private let machineID: String
    private let provider: any CollectiblesMachineProvider
    private let pollInterval: Duration
    private let appStateObserver: AppStateObserver
    private let isPurchaseLocked: @MainActor () -> Bool
    private let relinkStatusProvider: (any CollectiblesRelinkStatusProvider)?
    private weak var routable: (any CollectiblesMachineRoutable)?

    private var machine: CollectiblesMachine
    private var isOnScreen = false

    let prizePoolViewModel: CollectiblesPrizePoolViewModel

    private(set) var pollingTask: Task<Void, Never>?

    // MARK: - Publishers

    /// The header and the CTA render straight from the tapped pack, ahead of the first response.
    @Published private(set) var title: String
    @Published private(set) var artworkURL: URL?
    @Published private(set) var openButtonText: String
    @Published private(set) var isOpenLocked = false

    @Published private(set) var details: Details
    /// A purchase parameter, not a setting: it lives as long as the screen and rides along into the order.
    @Published var isTurboModeOn = false
    @Published var isTurboModeInfoPresented = false

    // MARK: - Init

    init(
        machineID: String,
        machine: CollectiblesMachine,
        routable: (any CollectiblesMachineRoutable)?,
        prizePoolProvider: any CollectiblesPrizePoolProvider,
        relinkStatusProvider: (any CollectiblesRelinkStatusProvider)?,
        isPurchaseLocked: @escaping @MainActor () -> Bool,
        provider: any CollectiblesMachineProvider = CollectiblesAPIService(),
        pollInterval: Duration = Constants.defaultPollInterval,
        notificationCenter: NotificationCenter = .default
    ) {
        self.routable = routable
        self.provider = provider
        self.pollInterval = pollInterval
        self.isPurchaseLocked = isPurchaseLocked
        self.relinkStatusProvider = relinkStatusProvider

        title = machine.name
        artworkURL = machine.artworkURL
        openButtonText = Self.makeOpenButtonText(price: machine.price)
        details = Mapper.map(machine)
        self.machine = machine
        self.machineID = machineID
        prizePoolViewModel = CollectiblesPrizePoolViewModel(machineID: machineID, provider: prizePoolProvider)
        appStateObserver = AppStateObserver(notificationCenter: notificationCenter)

        appStateObserver.start { [weak self] isInBackground in
            self?.updateAppActivity(isActive: !isInBackground)
        }

        isOpenLocked = isPurchaseLocked()

        relinkStatusProvider?.isRelinkRequiredPublisher
            .receiveOnMain()
            .map { [isPurchaseLocked] _ in isPurchaseLocked() }
            .assign(to: &$isOpenLocked)
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Methods

    func onWillAppear() {
        isOnScreen = true
        isOpenLocked = isPurchaseLocked()
        prizePoolViewModel.load()
        recheckRelinkStatus()

        guard pollingTask == nil else { return }

        startPolling()
    }

    func onWillDisappear() {
        isOnScreen = false
        cancelPolling()
    }

    func openOrder() {
        routable?.openConfirmOrder(machineID: machineID, machine: machine, isTurboModeOn: isTurboModeOn)
    }

    func showTurboModeInfo() {
        isTurboModeInfoPresented = true
    }

    func dismissTurboModeInfo() {
        isTurboModeInfoPresented = false
    }
}

// MARK: - Details

extension CollectiblesMachineViewModel {
    struct Details {
        let tiers: [TierChip]
        let cardsCountText: String?
        let buybackText: String
        let expectedValueText: String
    }

    struct TierChip: Identifiable {
        let tier: CollectiblesMachine.Tier
        let title: String
        let detailText: String?

        var id: CollectiblesMachine.Tier { tier }
    }
}

// MARK: - Private logic

private extension CollectiblesMachineViewModel {
    static func makeOpenButtonText(price: Decimal) -> String {
        let amount = CollectiblesPriceFormatter.formatAmount(price, ticker: Constants.paymentCurrencyCode)

        return Localization.collectiblesMachineOpenButton(amount)
    }

    func recheckRelinkStatus() {
        Task { [relinkStatusProvider] in
            await relinkStatusProvider?.refreshStateSilently()
        }
    }

    func startPolling(fetchesImmediately: Bool = false) {
        pollingTask?.cancel()

        let interval = pollInterval

        pollingTask = Task { @MainActor [weak self] in
            if fetchesImmediately {
                await self?.fetch()
            }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }

                await self?.fetch()
            }
        }
    }

    func cancelPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func updateAppActivity(isActive: Bool) {
        guard isOnScreen else { return }

        guard isActive else {
            cancelPolling()
            return
        }

        recheckRelinkStatus()

        guard pollingTask == nil else { return }

        startPolling(fetchesImmediately: true)
    }

    func applyHeader(from machine: CollectiblesMachine) {
        title = machine.name
        artworkURL = machine.artworkURL
        openButtonText = Self.makeOpenButtonText(price: machine.price)
    }

    func fetch() async {
        do {
            let machine = try await provider.load(id: machineID)
            guard !Task.isCancelled else { return }

            self.machine = machine
            applyHeader(from: machine)
            details = Mapper.map(machine)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }

            AppLogger.error("Collectibles machine \(machineID) failed to load", error: error)
        }
    }
}

// MARK: - Constants

extension CollectiblesMachineViewModel {
    enum Constants {
        /// The backend syncs machines with the partner every ~10 seconds; the ask is a 10-20 s refresh.
        static let defaultPollInterval: Duration = .seconds(10)
        /// The account spends USDC, while the values on the screen stay in dollars.
        static let paymentCurrencyCode = "USDC"
    }
}

// MARK: - Identifiable

extension CollectiblesMachineViewModel: Identifiable {}
