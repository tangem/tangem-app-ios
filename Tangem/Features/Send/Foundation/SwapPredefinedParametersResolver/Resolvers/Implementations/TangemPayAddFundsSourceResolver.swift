//
//  TangemPayAddFundsSourceResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
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
    private let preferredCurrencies: Set<ExpressWalletCurrency>

    init(
        userWalletModel: UserWalletModel,
        preferredTokenItems: [TokenItem]
    ) {
        userWalletInfo = userWalletModel.userWalletInfo
        walletModelsProvider = MainScreenUIOrderedWalletModelsProvider(userWalletModel: userWalletModel)
        preferredCurrencies = Set(preferredTokenItems.map(\.expressCurrency))
    }
}

// MARK: - SwapSourceTokenResolver

extension TangemPayAddFundsSourceResolver: SwapSourceTokenResolver {
    var initialSource: LoadingResult<SendSwapableToken, any Error> { .loading }

    func resolveSource(for receive: SendReceiveToken?) async throws -> SendSwapableToken {
        let walletModels = await walletModelsProvider.settledWalletModels()

        guard let source = resolveSourceToken(from: walletModels) else {
            throw SwapModel.SwapModelError.tokenSelectionRequired
        }

        return source
    }
}

// MARK: - Choosing the source

extension TangemPayAddFundsSourceResolver {
    static func chooseSource(
        from walletModels: [any WalletModel],
        preferredCurrencies: Set<ExpressWalletCurrency>,
        userWalletInfo: UserWalletInfo
    ) -> (any WalletModel)? {
        // A currency match makes the pair a plain transfer, which needs no Express support —
        // only the send gates apply, the swap availability bar is for the swap fallback.
        let preferred = walletModels.filter {
            preferredCurrencies.contains($0.tokenItem.expressCurrency)
                && isTransferAvailable(walletModel: $0, userWalletInfo: userWalletInfo)
        }

        if let preferredSource = preferred.mostFiatFundedOrFirst {
            return preferredSource
        }

        let candidates = walletModels.filter {
            TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: $0).isSwapAvailable(direction: .from)
        }
        return candidates.mostFiatFundedOrFirst
    }
}

// MARK: - Private

private extension TangemPayAddFundsSourceResolver {
    static func isTransferAvailable(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> Bool {
        let availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)

        return SwapSourcePreselectionEligibility.canBecomeSource(for: availabilityProvider.swapSourceAvailability())
            && availabilityProvider.isSendAvailable
    }

    func resolveSourceToken(from walletModels: [any WalletModel]) -> SendSwapableToken? {
        let chosen = Self.chooseSource(
            from: walletModels,
            preferredCurrencies: preferredCurrencies,
            userWalletInfo: userWalletInfo
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
