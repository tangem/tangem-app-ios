//
//  CommonTotalBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemPay
import TangemPolymarket
import TangemFoundation

class CommonTotalBalanceProvider {
    private let accountModelsManager: AccountModelsManager
    private let totalBalanceStatesCombiner: TotalBalanceStatesCombiner
    private let tokenBalanceTypesCombiner: TokenBalanceTypesCombiner
    private let analyticsLogger: TotalBalanceProviderAnalyticsLogger

    private let tangemPayTokenItem = TangemPayUtilities.usdcTokenItem
    private let polymarketTokenItem = PolymarketUtilities.collateralTokenItem
    private let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never> = .init(.loading(cached: .none))
    private var updateSubscription: AnyCancellable?

    init(
        accountModelsManager: AccountModelsManager,
        totalBalanceStatesCombiner: TotalBalanceStatesCombiner = .init(),
        tokenBalanceTypesCombiner: TokenBalanceTypesCombiner = .init(),
        analyticsLogger: TotalBalanceProviderAnalyticsLogger
    ) {
        self.accountModelsManager = accountModelsManager
        self.totalBalanceStatesCombiner = totalBalanceStatesCombiner
        self.tokenBalanceTypesCombiner = tokenBalanceTypesCombiner
        self.analyticsLogger = analyticsLogger

        analyticsLogger.setupTotalBalanceState(publisher: totalBalancePublisher)
        bind()
    }

    deinit {
        AppLogger.debug(self, "deinit")
    }
}

// MARK: - Private implementation

private extension CommonTotalBalanceProvider {
    func bind() {
        let crypto = AccountModelsAggregator(.crypto, .joint)
            .modelsPublisher(from: accountModelsManager)
            .flatMapLatest { cryptoAccountModels in
                cryptoAccountModels
                    .map(\.fiatTotalBalanceProvider.totalBalancePublisher)
                    .combineLatest()
            }

        let tangemPay = AccountModelsAggregator(.tangemPay)
            .modelPublisher(from: accountModelsManager)
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, accountModel -> AnyPublisher<TotalBalanceState, Never> in
                guard let accountModel else {
                    // If tangemPayAccountModel doesn't exist just return 0 as total balance
                    // That do not break a full total balance
                    return Just(TotalBalanceState.loaded(balance: 0)).eraseToAnyPublisher()
                }

                return accountModel
                    .statePublisher
                    .map(\.tangemPayAccount)
                    .withWeakCaptureOf(provider)
                    .flatMapLatest { provider, tangemPayAccount -> AnyPublisher<TotalBalanceState, Never> in
                        guard let tangemPayAccount else {
                            // If tangemPayAccount doesn't exist just return 0 as total balance
                            // That do not break a full total balance
                            return .just(output: TotalBalanceState.loaded(balance: 0)).eraseToAnyPublisher()
                        }

                        return tangemPayAccount
                            .balancesProvider
                            .fiatTotalTokenBalanceProvider
                            .balanceTypePublisher
                            .withWeakCaptureOf(provider)
                            .map { provider, balanceType in
                                let balance = TokenBalanceTypesCombiner.Balance(item: provider.tangemPayTokenItem, balance: balanceType)
                                return provider.tokenBalanceTypesCombiner.mapToTotalBalance(balances: [balance])
                            }
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }

        let polymarket = AccountModelsAggregator(.polymarket)
            .modelPublisher(from: accountModelsManager)
            .compactMap { $0 }
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, accountModel -> AnyPublisher<TotalBalanceState, Never> in
                Publishers
                    .CombineLatest(accountModel.statePublisher, accountModel.fiatTotalTokenBalanceProvider.balanceTypePublisher)
                    .withWeakCaptureOf(provider)
                    .map { provider, tuple in
                        let (state, balanceType) = tuple

                        guard state?.isAccountVisible == true else {
                            return TotalBalanceState.loaded(balance: 0)
                        }

                        let balance = TokenBalanceTypesCombiner.Balance(item: provider.polymarketTokenItem, balance: balanceType)

                        return provider.tokenBalanceTypesCombiner.mapToTotalBalance(balances: [balance])
                    }
                    .eraseToAnyPublisher()
            }
            .prepend(TotalBalanceState.loaded(balance: 0))

        updateSubscription = Publishers.CombineLatest3(
            crypto,
            tangemPay,
            polymarket
        )
        .map { $0 + [$1, $2] }
        .withWeakCaptureOf(self)
        .map { $0.totalBalanceStatesCombiner.mapToTotalBalanceState(states: $1) }
        .assign(to: \.totalBalanceSubject.value, on: self, ownership: .weak)
    }
}

// MARK: - TotalBalanceProvider

extension CommonTotalBalanceProvider: TotalBalanceProvider {
    var totalBalance: TotalBalanceState {
        totalBalanceSubject.value
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonTotalBalanceProvider: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
