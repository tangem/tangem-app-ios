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

protocol MainHeaderBalanceProvider {
    var balance: LoadableTokenBalanceView.State { get }
    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> { get }
}

class CommonMainHeaderBalanceProvider {
    private let totalBalanceProvider: TotalBalanceProviding
    private let userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider
    private let mainBalanceFormatter: MainHeaderBalanceFormatter

    init(
        totalBalanceProvider: TotalBalanceProviding,
        userWalletStateInfoProvider: MainHeaderUserWalletStateInfoProvider,
        mainBalanceFormatter: MainHeaderBalanceFormatter
    ) {
        self.totalBalanceProvider = totalBalanceProvider
        self.userWalletStateInfoProvider = userWalletStateInfoProvider
        self.mainBalanceFormatter = mainBalanceFormatter
    }

    private func mapToLoadableTokenBalanceViewState(state: TotalBalanceState) -> LoadableTokenBalanceView.State {
        if userWalletStateInfoProvider.isUserWalletLocked {
            // Show endless shimmer for locked wallet
            return .loading(cached: .none)
        }

        switch state {
        case .empty, .failed(.none, _):
            let formatted = mainBalanceFormatter.formatBalance(balance: .none)
            return .failed(cached: .attributed(formatted))
        case .loading(let cached):
            let formatted = cached.map { self.mainBalanceFormatter.formatBalance(balance: $0) }
            return .loading(cached: formatted.map { .attributed($0) })
        case .failed(.some(let cached), _):
            let formatted = mainBalanceFormatter.formatBalance(balance: cached)
            return .failed(cached: .attributed(formatted))
        case .loaded(let balance):
            let formatted = mainBalanceFormatter.formatBalance(balance: balance)
            return .loaded(text: .attributed(formatted))
        }
    }
}

// MARK: - MainHeaderBalanceProvider

extension CommonMainHeaderBalanceProvider: MainHeaderBalanceProvider {
    var balance: LoadableTokenBalanceView.State {
        mapToLoadableTokenBalanceViewState(state: totalBalanceProvider.totalBalance)
    }

    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> {
        totalBalanceProvider
            .totalBalancePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToLoadableTokenBalanceViewState(state: $1) }
            .eraseToAnyPublisher()
    }
}
