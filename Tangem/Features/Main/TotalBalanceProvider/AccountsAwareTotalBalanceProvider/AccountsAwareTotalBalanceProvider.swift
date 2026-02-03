//
//  AccountsAwareTotalBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemPay

class AccountsAwareTotalBalanceProvider {
    private let accountModelsManager: AccountModelsManager
    private let totalBalanceStatesCombiner: TotalBalanceStatesCombiner
    private let tokenBalanceTypesCombiner: TokenBalanceTypesCombiner
    private let analyticsLogger: TotalBalanceProviderAnalyticsLogger

    private let tangemPayTokenItem = TangemPayUtilities.usdcTokenItem
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
        AppLogger.debug("deinit \(self)")
    }
}

// MARK: - Private implementation

private extension AccountsAwareTotalBalanceProvider {
    func bind() {
        let crypto = accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccountModels in
                cryptoAccountModels
                    .map(\.fiatTotalBalanceProvider.totalBalancePublisher)
                    .combineLatest()
            }

        let tangemPay = accountModelsManager
            .tangemPayLocalStatePublisher
            .map(\.tangemPayAccount)
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, tangemPayAccount -> AnyPublisher<TotalBalanceState, Never> in
                guard let tangemPayAccount else {
                    // If tangemPayAccount doesn't exist just return 0 as total balance
                    // That do not break a full total balance
                    return .just(output: .loaded(balance: 0))
                }

                return tangemPayAccount
                    .balancesProvider
                    .fiatTotalTokenBalanceProvider
                    .balanceTypePublisher
                    .map { balanceType in
                        let balance = TokenBalanceTypesCombiner.Balance(item: provider.tangemPayTokenItem, balance: balanceType)
                        return provider.tokenBalanceTypesCombiner.mapToTotalBalance(balances: [balance])
                    }
                    .eraseToAnyPublisher()
            }

        updateSubscription = Publishers.CombineLatest(
            crypto,
            tangemPay
        )
        .map { $0 + [$1] }
        .withWeakCaptureOf(self)
        .map { $0.totalBalanceStatesCombiner.mapToTotalBalanceState(states: $1) }
        .assign(to: \.totalBalanceSubject.value, on: self, ownership: .weak)
    }
}

// MARK: - TotalBalanceProvider

extension AccountsAwareTotalBalanceProvider: TotalBalanceProvider {
    var totalBalance: TotalBalanceState {
        totalBalanceSubject.value
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}
