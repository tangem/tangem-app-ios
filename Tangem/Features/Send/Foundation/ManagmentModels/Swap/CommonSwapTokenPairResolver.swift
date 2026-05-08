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

    private let swapAvailabilityChecker: SwapAvailabilityChecker

    init(swapAvailabilityChecker: SwapAvailabilityChecker) {
        self.swapAvailabilityChecker = swapAvailabilityChecker
    }

    // MARK: - SwapTokenPairResolver

    func resolve(for origin: SwapPairResolvingOrigin) -> ResolvedSwapPair {
        switch origin {
        case .tokenDetails(let input):
            guard swapAvailabilityChecker.isSwapAvailable(walletModel: input.walletModel) else {
                return ResolvedSwapPair(source: nil, destination: nil)
            }
            let isExchangeable = expressAvailabilityProvider.canSwap(tokenItem: input.walletModel.tokenItem)
            return resolveFromTokenDetails(input, isExchangeable: isExchangeable)
        case .mainScreen(let input):
            return resolveFromMainScreen(input)
        case .markets(let input):
            guard swapAvailabilityChecker.isSwapAvailable(walletModel: input.walletModel) else {
                return ResolvedSwapPair(source: nil, destination: nil)
            }
            let isExchangeable = expressAvailabilityProvider.canSwap(tokenItem: input.walletModel.tokenItem)
            return resolveFromTokenDetails(.init(walletModel: input.walletModel), isExchangeable: isExchangeable)
        }
    }
}

// MARK: - Private

private extension CommonSwapTokenPairResolver {
    func resolveFromTokenDetails(
        _ input: SwapPairResolvingOrigin.TokenDetailsInput,
        isExchangeable: Bool
    ) -> ResolvedSwapPair {
        let hasBalance = input.walletModel.fiatBalance > 0

        // Token has balance → FROM = current, TO = manual selection
        if hasBalance {
            return ResolvedSwapPair(source: input.walletModel, destination: nil)
        }

        let groups = groupAccountTokens(for: input.walletModel)

        if isExchangeable {
            // Account has exchangeable token with balance
            if let topExchangeable = groups.topExchangeable {
                return ResolvedSwapPair(source: topExchangeable, destination: input.walletModel)
            }

            // Account has exchangeable token but without balance
            if groups.hasExchangeableEmpty {
                return ResolvedSwapPair(source: nil, destination: input.walletModel)
            }
        }

        // Most funded token in account
        if let topFunded = groups.mostFunded {
            return ResolvedSwapPair(source: topFunded, destination: input.walletModel)
        }

        // Fallback: no tokens with balance → first in account (or nil)
        return ResolvedSwapPair(source: groups.firstInAccount, destination: input.walletModel)
    }

    func groupAccountTokens(for walletModel: any WalletModel) -> AccountTokenGroups {
        let allModels = walletModel.account?.walletModelsManager.walletModels ?? []

        var groups = AccountTokenGroups()
        var mostFundedFiat: Decimal = 0
        var topExchangeableFiat: Decimal = 0

        for model in allModels {
            guard model.id != walletModel.id else { continue }
            guard swapAvailabilityChecker.isSwapAvailable(walletModel: model) else { continue }

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

// MARK: - Main Screen Resolution

private extension CommonSwapTokenPairResolver {
    func resolveFromMainScreen(_ input: SwapPairResolvingOrigin.MainScreenInput) -> ResolvedSwapPair {
        var firstSwapAvailable: (any WalletModel)?
        var mostFundedInWallet: (any WalletModel)?
        var mostFundedFiat: Decimal = 0

        for model in input.orderedWalletModels {
            guard swapAvailabilityChecker.isSwapAvailable(walletModel: model) else { continue }

            if firstSwapAvailable == nil {
                firstSwapAvailable = model
            }

            let fiat = model.fiatBalance
            if fiat > 0, fiat > mostFundedFiat {
                mostFundedFiat = fiat
                mostFundedInWallet = model
            }
        }

        // Most funded swap-available token in wallet
        if let mostFundedInWallet {
            return ResolvedSwapPair(source: mostFundedInWallet, destination: nil)
        }

        // First swap-available token in UI order (or nil if none)
        return ResolvedSwapPair(source: firstSwapAvailable, destination: nil)
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

// MARK: - Origin

enum SwapPairResolvingOrigin {
    case tokenDetails(TokenDetailsInput)
    case mainScreen(MainScreenInput)
    case markets(MarketsInput)

    struct TokenDetailsInput {
        let walletModel: any WalletModel
    }

    struct MainScreenInput {
        let orderedWalletModels: [any WalletModel]
    }

    struct MarketsInput {
        let walletModel: any WalletModel
    }
}

// MARK: - Result

struct ResolvedSwapPair {
    let source: (any WalletModel)?
    let destination: (any WalletModel)?
}
