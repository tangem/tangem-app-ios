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

class AccountsAwareTotalBalanceProvider {
    private let accountModelsManager: AccountModelsManager
    private let totalBalanceStatesCombiner: TotalBalanceStatesCombiner
    private let analyticsLogger: TotalBalanceProviderAnalyticsLogger

    private let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never> = .init(.loading(cached: .none))
    private var updateSubscription: AnyCancellable?

    init(
        accountModelsManager: AccountModelsManager,
        totalBalanceStatesCombiner: TotalBalanceStatesCombiner = .init(),
        analyticsLogger: TotalBalanceProviderAnalyticsLogger
    ) {
        self.accountModelsManager = accountModelsManager
        self.totalBalanceStatesCombiner = totalBalanceStatesCombiner
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
        updateSubscription = accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccountModels in
                cryptoAccountModels
                    .map(\.fiatTotalBalanceProvider.totalBalancePublisher)
                    .combineLatest()
            }
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
