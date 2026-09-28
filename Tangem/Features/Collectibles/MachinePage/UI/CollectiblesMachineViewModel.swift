//
//  CollectiblesMachineViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

@MainActor
final class CollectiblesMachineViewModel: ObservableObject {
    // MARK: - Properties

    private let machineID: String
    private let provider: any CollectiblesMachineProvider
    private let pollInterval: Duration

    let prizePoolViewModel: CollectiblesPrizePoolViewModel

    private(set) var pollingTask: Task<Void, Never>?

    // MARK: - Publishers

    /// The header and the CTA render straight from the tapped pack, ahead of the first response.
    @Published private(set) var title: String
    @Published private(set) var artworkURL: URL?
    @Published private(set) var openButtonText: String

    @Published private(set) var state: State = .loading

    // MARK: - Init

    init(
        pack: CollectiblesPack,
        prizePoolProvider: any CollectiblesPrizePoolProvider,
        provider: any CollectiblesMachineProvider = CollectiblesAPIService(),
        pollInterval: Duration = Constants.defaultPollInterval
    ) {
        title = pack.name
        artworkURL = pack.artworkURL
        openButtonText = Self.makeOpenButtonText(price: pack.price)
        machineID = pack.id
        self.provider = provider
        self.pollInterval = pollInterval
        prizePoolViewModel = CollectiblesPrizePoolViewModel(machineID: pack.id, provider: prizePoolProvider)
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Methods

    func load() {
        prizePoolViewModel.load()

        guard pollingTask == nil else { return }

        startPolling()
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func retry() {
        guard case .failed = state else { return }

        state = .loading
        startPolling()
    }
}

// MARK: - State

extension CollectiblesMachineViewModel {
    enum State {
        case loading
        case content(Details)
        case failed

        var isContent: Bool {
            if case .content = self {
                return true
            }
            return false
        }

        var isFailed: Bool {
            if case .failed = self {
                return true
            }
            return false
        }
    }

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

    func startPolling() {
        pollingTask?.cancel()

        let interval = pollInterval
        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.fetch()

                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
            }
        }
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

            applyHeader(from: machine)
            state = .content(Mapper.map(machine))
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }

            AppLogger.error("Collectibles machine \(machineID) failed to load", error: error)

            // A failed silent refresh keeps the last live values; the loop retries on the next tick anyway.
            guard !state.isContent else { return }

            state = .failed
        }
    }
}

// MARK: - Constants

extension CollectiblesMachineViewModel {
    enum Constants {
        /// The backend syncs machines with the partner every ~10 seconds; the ask is a 10-20 s refresh.
        static let defaultPollInterval: Duration = .seconds(15)
        /// The account spends USDC, while the values on the screen stay in dollars.
        static let paymentCurrencyCode = "USDC"
    }
}
