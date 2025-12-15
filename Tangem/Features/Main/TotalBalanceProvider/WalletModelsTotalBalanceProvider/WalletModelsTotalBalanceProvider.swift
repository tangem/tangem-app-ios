//
//  WalletModelsTotalBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

/// - Note: Used for both 'Legacy' and 'Accounts' app modes.
final class WalletModelsTotalBalanceProvider {
    private let walletModelsManager: WalletModelsManager
    private let analyticsLogger: TotalBalanceProviderAnalyticsLogger
    private let derivationManager: DerivationManager?
    private let totalBalanceStateBuilder: WalletModelsTotalBalanceStateBuilder

    private let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never>
    private var updateSubscription: AnyCancellable?

    init(
        walletModelsManager: WalletModelsManager,
        analyticsLogger: TotalBalanceProviderAnalyticsLogger,
        derivationManager: DerivationManager?
    ) {
        self.walletModelsManager = walletModelsManager
        self.analyticsLogger = analyticsLogger
        self.derivationManager = derivationManager

        totalBalanceStateBuilder = .init(walletModelsManager: walletModelsManager)
        totalBalanceSubject = .init(totalBalanceStateBuilder.buildTotalBalanceState())

        analyticsLogger.setupTotalBalanceState(publisher: totalBalancePublisher)
        bind()
    }

    deinit {
        AppLogger.debug("deinit \(self)")
    }
}

// MARK: - TotalBalanceProvider

extension WalletModelsTotalBalanceProvider: TotalBalanceProvider {
    var totalBalance: TotalBalanceState {
        totalBalanceSubject.value
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private implementation

private extension WalletModelsTotalBalanceProvider {
    func bind() {
        let hasEntriesWithoutDerivationPublisher = derivationManager?.hasPendingDerivations ?? .just(output: false)
        let balanceStatePublisher = walletModelsManager
            .walletModelsPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.global())
            .withWeakCaptureOf(self)
            .flatMapLatest { balanceProvider, walletModels in
                if walletModels.isEmpty {
                    return Just(TotalBalanceState.loaded(balance: 0)).eraseToAnyPublisher()
                }

                let publishers: [AnyPublisher<Void, Never>] = walletModels.map {
                    $0.fiatTotalTokenBalanceProvider
                        .balanceTypePublisher
                        .mapToVoid()
                        .eraseToAnyPublisher()
                }

                return publishers
                    // 1. Listen every change in all wallet models
                    .merge()
                    // 2. Add a small debounce to reduce the count of calculation
                    .debounce(for: 0.1, scheduler: DispatchQueue.global())
                    // 3. The latest data will be get from wallets in `totalBalanceStateBuilder`
                    // Because the data from the publishers can be outdated
                    // Why? I believe there can be race condition because
                    // `WalletModel` and `AccountTotalBalanceProvider` working via their own background queue
                    .withWeakCaptureOf(balanceProvider)
                    .map { $0.0.totalBalanceStateBuilder.buildTotalBalanceState() }
                    .eraseToAnyPublisher()
            }

        updateSubscription = Publishers.CombineLatest(
            balanceStatePublisher,
            hasEntriesWithoutDerivationPublisher
        )
        .withWeakCaptureOf(self)
        .sink { balanceProvider, input in
            let (state, hasEntriesWithoutDerivation) = input
            balanceProvider.updateState(state: state, hasEntriesWithoutDerivation: hasEntriesWithoutDerivation)
        }
    }

    func updateState(state: TotalBalanceState, hasEntriesWithoutDerivation: Bool) {
        guard !hasEntriesWithoutDerivation else {
            totalBalanceSubject.send(.empty)
            return
        }

        totalBalanceSubject.send(state)
    }
}

// MARK: - CustomStringConvertible

extension WalletModelsTotalBalanceProvider: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
