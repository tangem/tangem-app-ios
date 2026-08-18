//
//  CommonSwapTokenPairResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Result

struct ResolvedSwapPair {
    let source: (any WalletModel)?
    let destination: (any WalletModel)?
}

// MARK: - Token Details Resolver

final class TokenDetailsSwapPairResolver {
    @Injected(\.expressAvailabilityProvider) private var expressAvailabilityProvider: ExpressAvailabilityProvider

    private let swapAvailabilityChecker: SwapAvailabilityChecker

    init(swapAvailabilityChecker: SwapAvailabilityChecker) {
        self.swapAvailabilityChecker = swapAvailabilityChecker
    }

    func resolve(walletModel: any WalletModel) -> ResolvedSwapPair {
        guard swapAvailabilityChecker.isSwapAvailable(walletModel: walletModel) else {
            return ResolvedSwapPair(source: nil, destination: nil)
        }

        let isExchangeable = expressAvailabilityProvider.canSwap(tokenItem: walletModel.tokenItem)
        let hasBalance = walletModel.fiatAvailableBalance > 0

        if hasBalance {
            return ResolvedSwapPair(source: walletModel, destination: nil)
        }

        let groups = groupAccountTokens(for: walletModel)

        if isExchangeable {
            if let topExchangeable = groups.topExchangeable {
                return ResolvedSwapPair(source: topExchangeable, destination: walletModel)
            }

            if groups.hasExchangeableEmpty {
                return ResolvedSwapPair(source: nil, destination: walletModel)
            }
        }

        if let topFunded = groups.mostFunded {
            return ResolvedSwapPair(source: topFunded, destination: walletModel)
        }

        return ResolvedSwapPair(source: groups.firstInAccount, destination: walletModel)
    }
}

// MARK: - Private

private extension TokenDetailsSwapPairResolver {
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
        guard let chosenWalletModel = candidates.mostFiatFunded ?? candidates.first else {
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

        guard let source = candidates.mostFiatFunded ?? candidates.first else {
            return nil
        }

        return CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: source,
            operationType: .swap
        ).makeSwapableToken()
    }
}
