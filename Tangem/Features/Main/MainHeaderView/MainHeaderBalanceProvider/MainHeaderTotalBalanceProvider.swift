//
//  MainHeaderTotalBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemUI

protocol MainHeaderBalanceProvider {
    var balance: LoadableBalanceView.State { get }
    var balancePublisher: AnyPublisher<LoadableBalanceView.State, Never> { get }
}

final class CommonMainHeaderBalanceProvider {
    private let totalBalanceProvider: TotalBalanceProvider
    private let userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider
    private let mainBalanceFormatter: MainHeaderBalanceFormatter

    init(
        totalBalanceProvider: TotalBalanceProvider,
        userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider,
        mainBalanceFormatter: MainHeaderBalanceFormatter
    ) {
        self.totalBalanceProvider = totalBalanceProvider
        self.userWalletStateInfoProvider = userWalletStateInfoProvider
        self.mainBalanceFormatter = mainBalanceFormatter
    }

    private func mapToLoadableBalanceViewState(state: TotalBalanceState, currencyCode: String) -> LoadableBalanceView.State {
        if userWalletStateInfoProvider.isUserWalletLocked {
            // Show endless shimmer for locked wallet
            return .loading(cached: .none)
        }

        switch state {
        case .empty, .failed(.none, _):
            let formatted = mainBalanceFormatter.formatBalance(balance: .none, currencyCode: currencyCode)
            return .failed(cached: .attributed(formatted))

        case .loading(let cached):
            let formatted = cached.map { self.mainBalanceFormatter.formatBalance(balance: $0, currencyCode: currencyCode) }
            return .loading(cached: formatted.map { .attributed($0) })

        case .failed(.some(let cached), _):
            let formatted = mainBalanceFormatter.formatBalance(balance: cached, currencyCode: currencyCode)
            return .failed(cached: .attributed(formatted))

        case .loaded(let balance):
            let formatted = mainBalanceFormatter.formatBalance(balance: balance, currencyCode: currencyCode)
            return .loaded(text: .attributed(formatted))
        }
    }
}

// MARK: - MainHeaderBalanceProvider

extension CommonMainHeaderBalanceProvider: MainHeaderBalanceProvider {
    var balance: LoadableBalanceView.State {
        mapToLoadableBalanceViewState(
            state: totalBalanceProvider.totalBalance,
            currencyCode: AppSettings.shared.selectedCurrencyCode
        )
    }

    var balancePublisher: AnyPublisher<LoadableBalanceView.State, Never> {
        totalBalanceProvider
            .totalBalancePublisher
            .withAppCurrencyCode()
            .withWeakCaptureOf(self)
            .map { provider, input in
                let (state, currencyCode) = input
                return provider.mapToLoadableBalanceViewState(state: state, currencyCode: currencyCode)
            }
            .eraseToAnyPublisher()
    }
}
