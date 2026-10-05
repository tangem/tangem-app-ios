//
//  CollectiblesConfirmOrderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemCollectibles
import TangemLocalization

@MainActor
final class CollectiblesConfirmOrderViewModel: ObservableObject {
    // MARK: - Properties

    private let machineID: String
    private let isTurboModeOn: Bool
    private let total: Decimal
    private let refreshBalance: () async -> Void

    private var balanceState: BalanceState = .loading
    private var orderPhase: OrderPhase = .idle
    private var bag = Set<AnyCancellable>()

    let artworkURL: URL?
    let rows: [OrderRow]

    // MARK: - Publishers

    @Published private(set) var buttonState: ButtonState = .balanceLoading
    @Published private(set) var revealViewModel: CollectiblesPackRevealViewModel?

    // MARK: - Init

    init(
        machineID: String,
        machine: CollectiblesMachine,
        isTurboModeOn: Bool,
        usdcBalanceProvider: any TokenBalanceProvider,
        refreshBalance: @escaping () async -> Void
    ) {
        self.machineID = machineID
        self.isTurboModeOn = isTurboModeOn
        total = machine.price + machine.platformFee
        self.refreshBalance = refreshBalance
        artworkURL = machine.artworkURL
        rows = [
            OrderRow(
                title: "\(machine.name) x1",
                value: CollectiblesPriceFormatter.format(machine.price),
                isTotal: false
            ),
            OrderRow(
                title: Localization.collectiblesConfirmOrderPlatformFee,
                value: CollectiblesPriceFormatter.format(machine.platformFee),
                isTotal: false
            ),
            OrderRow(
                title: Localization.collectiblesConfirmOrderTotal,
                value: CollectiblesPriceFormatter.formatAmount(
                    total,
                    ticker: CollectiblesChainEnvironment.usdcTokenItem.currencySymbol
                ),
                isTotal: true
            ),
        ]

        bind(usdcBalanceProvider: usdcBalanceProvider)
    }

    // MARK: - Methods

    func approve() {
        guard buttonState == .approve else { return }

        orderPhase = .generating
        updateButtonState()

        Task { [weak self] in
            // [REDACTED_TODO_COMMENT]
            try await Task.sleep(for: .seconds(1.5))
            // [REDACTED_TODO_COMMENT]
            self?.revealViewModel = CollectiblesPackRevealViewModel(
                videoURL: Bundle.main.url(forResource: "CollectiblesPackReveal", withExtension: "mp4"),
                prize: .sample
            )
            self?.orderPhase = .generated
            self?.updateButtonState()
        }
    }

    func retryBalance() {
        guard buttonState == .balanceUnavailable else { return }

        balanceState = .loading
        updateButtonState()

        Task { [refreshBalance] in
            await refreshBalance()
        }
    }
}

// MARK: - Nested types

extension CollectiblesConfirmOrderViewModel {
    struct OrderRow: Hashable {
        let title: String
        let value: String
        let isTotal: Bool
    }

    enum ButtonState {
        case balanceLoading
        case balanceUnavailable
        case approve
        case notEnoughFunds
        case generating
        case packGenerated
    }
}

// MARK: - Order phase

private extension CollectiblesConfirmOrderViewModel {
    enum OrderPhase {
        case idle
        case generating
        case generated
    }

    enum BalanceState {
        case loading
        case known(Decimal)
        case unavailable
    }
}

// MARK: - Private logic

private extension CollectiblesConfirmOrderViewModel {
    func bind(usdcBalanceProvider: any TokenBalanceProvider) {
        usdcBalanceProvider.balanceTypePublisher
            .map(Self.balanceState(from:))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balanceState in
                self?.balanceState = balanceState
                self?.updateButtonState()
            }
            .store(in: &bag)
    }

    func updateButtonState() {
        switch orderPhase {
        case .idle:
            break
        case .generating:
            buttonState = .generating
            return
        case .generated:
            buttonState = .packGenerated
            return
        }

        switch balanceState {
        case .loading:
            buttonState = .balanceLoading
        case .unavailable:
            buttonState = .balanceUnavailable
        case .known(let balance):
            buttonState = balance >= total ? .approve : .notEnoughFunds
        }
    }

    nonisolated static func balanceState(from balanceType: TokenBalanceType) -> BalanceState {
        switch balanceType {
        case .loaded(let balance): .known(balance)
        case .loading: .loading
        case .failure, .empty: .unavailable
        }
    }
}
