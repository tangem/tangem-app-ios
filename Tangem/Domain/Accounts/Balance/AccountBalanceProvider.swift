//
//  AccountBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI

protocol AccountBalanceProvider: TotalBalanceProvider {
    var totalFiatBalance: LoadableBalanceView.State { get }
    var totalFiatBalancePublisher: AnyPublisher<LoadableBalanceView.State, Never> { get }
}

class CommonAccountBalanceProvider {
    private let totalBalanceProvider: TotalBalanceProvider
    private let loadableTokenBalanceViewStateBuilder = LoadableBalanceViewStateBuilder()

    init(totalBalanceProvider: TotalBalanceProvider) {
        self.totalBalanceProvider = totalBalanceProvider
    }
}

// MARK: - AccountBalanceProvider

extension CommonAccountBalanceProvider: AccountBalanceProvider {
    var totalBalance: TotalBalanceState {
        totalBalanceProvider.totalBalance
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceProvider.totalBalancePublisher
    }

    var totalFiatBalance: LoadableBalanceView.State {
        loadableTokenBalanceViewStateBuilder.buildTotalBalance(
            state: totalBalanceProvider.totalBalance,
            currencyCode: AppSettings.shared.selectedCurrencyCode
        )
    }

    var totalFiatBalancePublisher: AnyPublisher<LoadableBalanceView.State, Never> {
        totalBalanceProvider.totalBalancePublisher
            .withAppCurrencyCode()
            .withWeakCaptureOf(self)
            .map { provider, input in
                let (state, currencyCode) = input
                return provider.loadableTokenBalanceViewStateBuilder.buildTotalBalance(state: state, currencyCode: currencyCode)
            }
            .eraseToAnyPublisher()
    }
}
