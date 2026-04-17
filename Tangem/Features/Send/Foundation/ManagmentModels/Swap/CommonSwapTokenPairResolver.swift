//
//  CommonSwapTokenPairResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonSwapTokenPairResolver {
    // MARK: - Dependencies

    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    // MARK: - SwapTokenPairResolver

    func resolve(for source: SwapPairResolvingSource) -> ResolvedSwapPair {
        switch source {
        case .tokenDetails(let input):
            let isExchangeable = expressAvailabilityProvider.canSwap(tokenItem: input.walletModel.tokenItem)
            return resolveFromTokenDetails(input, isExchangeable: isExchangeable)
        }
    }
}

// MARK: - Private

private extension CommonSwapTokenPairResolver {
    func resolveFromTokenDetails(
        _ input: SwapPairResolvingSource.TokenDetailsInput,
        isExchangeable: Bool
    ) -> ResolvedSwapPair {
        let hasBalance = input.walletModel.fiatBalance > 0

        // Scenario 1 / 6: token has balance → FROM = current, TO = manual selection
        if hasBalance {
            return ResolvedSwapPair(source: input.walletModel, destination: nil)
        }

        let groups = groupAccountTokens(for: input.walletModel)

        if isExchangeable {
            // Scenario 2: account has exchangeable token with balance
            if let topExchangeable = groups.topExchangeable {
                return ResolvedSwapPair(source: topExchangeable, destination: input.walletModel)
            }

            // Scenario 3: account has exchangeable token but without balance
            if groups.hasExchangeableEmpty {
                return ResolvedSwapPair(source: nil, destination: input.walletModel)
            }
        }

        // Scenario 5 / 7: most funded token in account
        if let topFunded = groups.mostFunded {
            return ResolvedSwapPair(source: topFunded, destination: input.walletModel)
        }

        // Scenario 4 / 7 fallback: no tokens with balance → first in account (or nil)
        return ResolvedSwapPair(source: groups.firstInAccount, destination: input.walletModel)
    }

    func groupAccountTokens(for walletModel: any WalletModel) -> AccountTokenGroups {
        let allModels = walletModel.account?.walletModelsManager.walletModels ?? []

        var groups = AccountTokenGroups()
        var mostFundedFiat: Decimal = 0
        var topExchangeableFiat: Decimal = 0

        for model in allModels {
            guard model.id != walletModel.id else { continue }

            if groups.firstInAccount == nil {
                groups.firstInAccount = model
            }

            let isExchangeable = expressAvailabilityProvider.canSwap(tokenItem: model.tokenItem)
            let fiat = model.fiatBalance
            let hasBalance = fiat > 0

            if hasBalance, fiat > mostFundedFiat {
                mostFundedFiat = fiat
                groups.mostFunded = model
            }

            switch (isExchangeable, hasBalance) {
            case (true, true):
                if fiat > topExchangeableFiat {
                    topExchangeableFiat = fiat
                    groups.topExchangeable = model
                }
            case (true, false):
                groups.hasExchangeableEmpty = true
            default:
                break
            }
        }

        return groups
    }
}

// MARK: - AccountTokenGroups

private extension CommonSwapTokenPairResolver {
    struct AccountTokenGroups {
        /// Most funded exchangeable token with balance
        var topExchangeable: (any WalletModel)?
        var hasExchangeableEmpty: Bool = false
        /// Most funded token across all groups (exchangeable and non-exchangeable)
        var mostFunded: (any WalletModel)?
        /// First token in account by user's sort order (excluding current)
        var firstInAccount: (any WalletModel)?
    }
}

// MARK: - Helpers

private extension WalletModel {
    var fiatBalance: Decimal {
        fiatAvailableBalanceProvider.balanceType.value ?? 0
    }
}

private extension Array where Element == any WalletModel {
    mutating func sortByFiatBalance() {
        sort { $0.fiatBalance > $1.fiatBalance }
    }
}

// MARK: - Source

enum SwapPairResolvingSource {
    case tokenDetails(TokenDetailsInput)

    struct TokenDetailsInput {
        let walletModel: any WalletModel
    }
}

// MARK: - Result

struct ResolvedSwapPair {
    /// nil means user must select manually
    let source: (any WalletModel)?
    /// nil means user must select manually
    let destination: (any WalletModel)?
}

// MARK: - Error

enum SwapTokenPairResolverError: Error {
    case notImplemented
}
