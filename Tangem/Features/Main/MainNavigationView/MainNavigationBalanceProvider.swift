//
//  MainNavigationBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import Combine
import TangemFoundation
import TangemUI

final class MainNavigationBalanceProvider {
    private let balanceFormatter = BalanceFormatter()

    private let balanceFormattingOptions = TotalBalanceFormattingOptions(
        integerPartFont: DesignSystem.Font.bodyMediumToken,
        fractionalPartFont: DesignSystem.Font.bodyMediumToken,
        integerPartColor: .Tangem.Text.Neutral.primary,
        fractionalPartColor: .Tangem.Text.Neutral.secondary,
        fractionalPartIncludesDecimalSeparator: true
    )

    private let isUserWalletLocked: Bool
    private let totalBalanceProvider: TotalBalanceProvider

    var balance: MainNavigationBalanceState {
        mapToBalanceState(state: totalBalanceProvider.totalBalance)
    }

    var balancePublisher: AnyPublisher<MainNavigationBalanceState, Never> {
        totalBalanceProvider
            .totalBalancePublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToBalanceState(state: $1) }
            .eraseToAnyPublisher()
    }

    init(
        isUserWalletLocked: Bool,
        totalBalanceProvider: TotalBalanceProvider
    ) {
        self.isUserWalletLocked = isUserWalletLocked
        self.totalBalanceProvider = totalBalanceProvider
    }

    private func mapToBalanceState(state: TotalBalanceState) -> MainNavigationBalanceState {
        if isUserWalletLocked {
            return .empty
        }

        switch state {
        case .empty, .failed:
            return .empty

        case .loading(let cached):
            let formatted = cached.map { formatBalance(balance: $0) }
            return .loading(text: formatted.map { .attributed($0) })

        case .loaded(let balance):
            let formatted = formatBalance(balance: balance)
            return .loaded(text: .attributed(formatted))
        }
    }

    private func formatBalance(balance: Decimal?) -> AttributedString {
        let formattedBalance = balanceFormatter.formatFiatBalance(balance)
        return balanceFormatter.formatAttributedTotalBalance(
            fiatBalance: formattedBalance,
            formattingOptions: balanceFormattingOptions
        )
    }
}
