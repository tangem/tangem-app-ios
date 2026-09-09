//
//  PolymarketDepositSourceResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Picks the "From" token for a Polymarket deposit, in priority order:
/// 1. A transferable token in the currency the bridge accepts — the richest by fiat, else the
///    first in UI order. Keeps the operation a plain transfer, so Express swap support is not
///    required.
/// 2. Otherwise a swap-available token — the richest by fiat, else the first in UI order.
/// 3. Otherwise `nil`, leaving the source unselected for the user to pick manually.
final class PolymarketDepositSourceResolver {
    private let userWalletInfo: UserWalletInfo
    private let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider
    private let availabilityChecker: FundingSourceAvailabilityChecker
    private let depositCurrency: ExpressWalletCurrency

    init(
        userWalletInfo: UserWalletInfo,
        walletModelsProvider: MainScreenUIOrderedWalletModelsProvider,
        depositCurrency: ExpressWalletCurrency,
        availabilityChecker: FundingSourceAvailabilityChecker
    ) {
        self.userWalletInfo = userWalletInfo
        self.walletModelsProvider = walletModelsProvider
        self.depositCurrency = depositCurrency
        self.availabilityChecker = availabilityChecker
    }
}

// MARK: - SwapSourceTokenResolver

extension PolymarketDepositSourceResolver: SwapSourceTokenResolver {
    func resolve() async -> SendSwapableToken? {
        let walletModels = await walletModelsProvider.settledWalletModels()
        return resolveSourceToken(from: walletModels)
    }
}

// MARK: - Choosing the source

extension PolymarketDepositSourceResolver {
    static func chooseSource(
        from walletModels: [any WalletModel],
        depositCurrency: ExpressWalletCurrency,
        availabilityChecker: FundingSourceAvailabilityChecker
    ) -> (any WalletModel)? {
        // The bridge's own currency makes the pair a plain transfer, which needs no Express
        // support — only the send gates apply, the swap availability bar is for the swap fallback.
        let matching = walletModels.filter {
            $0.tokenItem.expressCurrency == depositCurrency
                && availabilityChecker.isTransferAvailable(walletModel: $0)
        }

        if let matchingSource = matching.mostFiatFundedOrFirst {
            return matchingSource
        }

        let candidates = walletModels.filter { availabilityChecker.isSwapAvailable(walletModel: $0) }
        return candidates.mostFiatFundedOrFirst
    }
}

// MARK: - Private implementation

private extension PolymarketDepositSourceResolver {
    func resolveSourceToken(from walletModels: [any WalletModel]) -> SendSwapableToken? {
        let chosen = Self.chooseSource(
            from: walletModels,
            depositCurrency: depositCurrency,
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
