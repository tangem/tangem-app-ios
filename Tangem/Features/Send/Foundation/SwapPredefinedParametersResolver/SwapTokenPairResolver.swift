//
//  CommonSwapTokenPairResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Token Details Resolver

final class TokenDetailsSwapSourceResolver {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let swapAvailabilityChecker: SwapAvailabilityChecker

    init(swapAvailabilityChecker: SwapAvailabilityChecker) {
        self.swapAvailabilityChecker = swapAvailabilityChecker
    }

    func resolveSource(for destination: any WalletModel) -> (any WalletModel)? {
        let isExchangeable = expressAvailabilityProvider.canSwap(tokenItem: destination.tokenItem)
        let groups = groupAccountTokens(for: destination)

        if isExchangeable {
            if let topExchangeable = groups.topExchangeable {
                return topExchangeable
            }

            if groups.hasExchangeableEmpty {
                return nil
            }
        }

        return groups.mostFunded ?? groups.firstInAccount
    }
}

// MARK: - Private

private extension TokenDetailsSwapSourceResolver {
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
            let fiat = model.fiatAvailableBalance
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

    struct AccountTokenGroups {
        var topExchangeable: (any WalletModel)?
        var hasExchangeableEmpty: Bool = false
        var mostFunded: (any WalletModel)?
        var firstInAccount: (any WalletModel)?
    }
}

// MARK: - Main Resolver

final class MainSwapSourceResolver {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let swapAvailabilityChecker: SwapAvailabilityChecker
    private let userWalletInfo: UserWalletInfo
    private let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider

    init(
        userWalletModel: UserWalletModel,
        swapAvailabilityChecker: SwapAvailabilityChecker
    ) {
        self.swapAvailabilityChecker = swapAvailabilityChecker
        userWalletInfo = userWalletModel.userWalletInfo
        walletModelsProvider = MainScreenUIOrderedWalletModelsProvider(userWalletModel: userWalletModel)
    }

    func resolve() async -> SendSwapableToken? {
        let walletModels = await walletModelsProvider.settledWalletModels()
        return resolveSourceToken(from: walletModels)
    }

    static func makeBestEffortSourceToken(
        from walletModels: [any WalletModel],
        userWalletInfo: UserWalletInfo
    ) -> SendSwapableToken? {
        let expressAvailabilityProvider = InjectedValues[\.expressAvailabilityProvider]

        let candidates = walletModels.filter { walletModel in
            expressAvailabilityProvider.swapState(for: walletModel.tokenItem) != .unavailable
        }

        // Balances are usually still loading here, hence the fallback to the first candidate.
        guard let chosenWalletModel = candidates.mostFiatFundedOrFirst else {
            return nil
        }

        return CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: chosenWalletModel,
            operationType: .swap
        ).makeSwapableToken()
    }
}

// MARK: - SwapSourceTokenResolver

extension MainSwapSourceResolver: SwapSourceTokenResolver {}

// MARK: - Private

private extension MainSwapSourceResolver {
    func resolveSourceToken(from walletModels: [any WalletModel]) -> SendSwapableToken? {
        let candidates = walletModels.filter { swapAvailabilityChecker.isSwapAvailable(walletModel: $0) }

        guard let source = candidates.mostFiatFundedOrFirst else {
            return nil
        }

        return CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: source,
            operationType: .swap
        ).makeSwapableToken()
    }
}
