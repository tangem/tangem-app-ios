//
//  TotalBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

class TotalBalanceProvider {
    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?
    private let totalBalanceStateBuilder: TotalBalanceStateBuilder

    private let queue = DispatchQueue(label: "com.tangem.TotalBalanceProvider")
    private let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never>

    private var walletModelsSubscription: AnyCancellable?
    private var updateSubscription: AnyCancellable?

    init(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager,
        derivationManager: DerivationManager?
    ) {
        self.userWalletId = userWalletId
        self.walletModelsManager = walletModelsManager
        self.derivationManager = derivationManager
        totalBalanceStateBuilder = .init()

        let balances = walletModelsManager.walletModels.map {
            (item: $0.tokenItem, balance: $0.fiatTotalTokenBalanceProvider.balanceType)
        }

        totalBalanceSubject = .init(totalBalanceStateBuilder.mapToTotalBalance(balances: balances))
        bind()
    }

    deinit {
        AppLog.shared.debug("deinit \(self)")
    }
}

// MARK: - TotalBalanceProviding protocol conformance

extension TotalBalanceProvider: TotalBalanceProviding {
    var totalBalance: TotalBalanceState {
        totalBalanceSubject.value
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private implementation

private extension TotalBalanceProvider {
    func bind() {
        let hasEntriesWithoutDerivationPublisher = derivationManager?.hasPendingDerivations ?? .just(output: false)
        let balanceStatePublisher = walletModelsManager
            .walletModelsPublisher
            .removeDuplicates()
            .receive(on: queue)
            .withWeakCaptureOf(self)
            .flatMapLatest { balanceProvider, walletModels in
                if walletModels.isEmpty {
                    return Just(TotalBalanceState.loaded(balance: 0)).eraseToAnyPublisher()
                }

                return walletModels.map { walletModel in
                    walletModel.fiatTotalTokenBalanceProvider
                        .balanceTypePublisher
                        .withWeakCaptureOf(walletModel)
                        .map { (item: $0.tokenItem, balance: $1) }
                }
                // Collect any/all changes in wallet models
                .combineLatest()
                .withWeakCaptureOf(balanceProvider)
                .map { $0.totalBalanceStateBuilder.mapToTotalBalance(balances: $1) }
                .eraseToAnyPublisher()
            }

        walletModelsSubscription = Publishers.CombineLatest(
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

        // Analytics
        trackBalanceLoaded(state: state, tokensCount: walletModelsManager.walletModels.count)
        trackTokenBalanceLoaded(walletModels: walletModelsManager.walletModels)

        if case .loaded(let loadedBalance) = state {
            Analytics.logTopUpIfNeeded(balance: loadedBalance, for: userWalletId)
        }
    }

    func mapToBalanceParameterValue(state: TotalBalanceState) -> Analytics.ParameterValue? {
        switch state {
        case .empty: .noRate
        case .loading: .none
        case .failed: .blockchainError
        case .loaded(let balance) where balance > .zero: .full
        case .loaded: .empty
        }
    }

    // MARK: - Analytics

    func trackBalanceLoaded(state: TotalBalanceState, tokensCount: Int) {
        guard let balance = mapToBalanceParameterValue(state: state) else {
            return
        }

        Analytics.log(
            event: .balanceLoaded,
            params: [
                .balance: balance.rawValue,
                .tokensCount: tokensCount.description,
            ],
            limit: .userWalletSession(userWalletId: userWalletId)
        )
    }

    func trackTokenBalanceLoaded(walletModels: [WalletModel]) {
        let trackedItems = walletModels.compactMap { walletModel -> (symbol: String, balance: Decimal)? in
            switch (walletModel.tokenItem.blockchain, walletModel.fiatTotalTokenBalanceProvider.balanceType) {
            case (.polkadot, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            case (.kusama, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            case (.azero, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            // Other don't tracking
            default: .none
            }
        }

        trackedItems.forEach { symbol, balance in
            let positiveBalance = balance > 0

            Analytics.log(
                event: .tokenBalanceLoaded,
                params: [
                    .token: symbol,
                    .state: positiveBalance ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
                ],
                limit: .userWalletSession(userWalletId: userWalletId, extraEventId: symbol)
            )
        }
    }
}

// MARK: - CustomStringConvertible

extension TotalBalanceProvider: CustomStringConvertible {
    var description: String {
        TangemFoundation.objectDescription(self)
    }
}
