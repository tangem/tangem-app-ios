//
//  TokenSummaryPrimaryActionProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

/// Resolves the Token Summary primary action from the coin's holdings by balance.
enum TokenSummaryPrimaryActionProvider {
    /// A `nil` `currencyId` identifies no coin — matching on it would lump together every unmapped custom token.
    static func coinHoldings(of tokenItem: TokenItem, in userWalletModels: [any UserWalletModel]) -> [any WalletModel] {
        guard let currencyId = tokenItem.currencyId else {
            return []
        }

        return userWalletModels
            .filter { !$0.isUserWalletLocked }
            .flatMap { userWalletModel in
                AccountWalletModelsAggregator
                    .walletModels(from: userWalletModel.accountModelsManager)
                    .filter { $0.tokenItem.currencyId == currencyId }
            }
    }

    static func fundedHoldings(of tokenItem: TokenItem, in userWalletModels: [any UserWalletModel]) -> [any WalletModel] {
        coinHoldings(of: tokenItem, in: userWalletModels).filter { $0.availableBalanceProvider.isFunded }
    }

    static func makePublisher(balanceProviders: [any TokenBalanceProvider]) -> AnyPublisher<TokenSummaryPrimaryAction?, Never> {
        balanceProviders.primaryActionPublisher
    }
}

// MARK: - Private helpers

private extension Array where Element == any TokenBalanceProvider {
    /// Recomputes on every balance change, seeded with the current balances.
    var primaryActionPublisher: AnyPublisher<TokenSummaryPrimaryAction?, Never> {
        guard isNotEmpty else {
            return .just(output: nil)
        }

        return balanceChangePublisher
            .map { _ in currentAction }
            .prepend(currentAction)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var currentAction: TokenSummaryPrimaryAction? {
        contains(where: \.isFunded) ? .goToSwap(isEnabled: true) : .addFunds
    }

    var balanceChangePublisher: AnyPublisher<Void, Never> {
        Publishers
            .MergeMany(map { $0.balanceTypePublisher.mapToVoid().eraseToAnyPublisher() })
            .eraseToAnyPublisher()
    }
}
