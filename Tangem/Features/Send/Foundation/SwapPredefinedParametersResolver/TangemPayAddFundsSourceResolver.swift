//
//  TangemPayAddFundsSourceResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Picks the "From" token for Tangem Pay "Add funds", in priority order:
/// 1. A transferable token whose currency matches one the account itself holds — the richest
///    by fiat, else the first in UI order. Keeps the operation a plain transfer, so Express
///    swap support is not required.
/// 2. Otherwise a swap-available token — the richest by fiat, else the first in UI order,
///    the same rule the Main entry uses.
/// 3. Otherwise `nil`, leaving the source unselected for the user to pick manually.
final class TangemPayAddFundsSourceResolver {
    private let userWalletInfo: UserWalletInfo
    private let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider
    private let availabilityChecker: FundingSourceAvailabilityChecker
    private let preferredCurrencies: Set<ExpressWalletCurrency>

    init(
        userWalletModel: UserWalletModel,
        preferredTokenItems: [TokenItem],
        availabilityChecker: FundingSourceAvailabilityChecker
    ) {
        userWalletInfo = userWalletModel.userWalletInfo
        walletModelsProvider = MainScreenUIOrderedWalletModelsProvider(userWalletModel: userWalletModel)
        self.availabilityChecker = availabilityChecker
        preferredCurrencies = Set(preferredTokenItems.map(\.expressCurrency))
    }
}

// MARK: - SwapSourceTokenResolver

extension TangemPayAddFundsSourceResolver: SwapSourceTokenResolver {
    func resolve() async -> SendSwapableToken? {
        let walletModels = await walletModelsProvider.settledWalletModels()
        return resolveSourceToken(from: walletModels)
    }
}

// MARK: - Choosing the source

extension TangemPayAddFundsSourceResolver {
    static func chooseSource(
        from walletModels: [any WalletModel],
        preferredCurrencies: Set<ExpressWalletCurrency>,
        availabilityChecker: FundingSourceAvailabilityChecker
    ) -> (any WalletModel)? {
        // A currency match makes the pair a plain transfer, which needs no Express support —
        // only the send gates apply, the swap availability bar is for the swap fallback.
        let preferred = walletModels.filter {
            preferredCurrencies.contains($0.tokenItem.expressCurrency)
                && availabilityChecker.isTransferAvailable(walletModel: $0)
        }

        if let preferredSource = preferred.mostFiatFundedOrFirst {
            return preferredSource
        }

        let candidates = walletModels.filter { availabilityChecker.isSwapAvailable(walletModel: $0) }
        return candidates.mostFiatFundedOrFirst
    }
}

// MARK: - Private

private extension TangemPayAddFundsSourceResolver {
    func resolveSourceToken(from walletModels: [any WalletModel]) -> SendSwapableToken? {
        let chosen = Self.chooseSource(
            from: walletModels,
            preferredCurrencies: preferredCurrencies,
            availabilityChecker: availabilityChecker
        )

        guard let chosen else {
            return nil
        }

        return CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: chosen,
            operationType: .swap
        ).makeSwapableToken()
    }
}
