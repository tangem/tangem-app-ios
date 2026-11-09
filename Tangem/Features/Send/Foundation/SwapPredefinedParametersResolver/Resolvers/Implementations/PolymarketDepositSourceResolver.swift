//
//  PolymarketDepositSourceResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemExpress

final class PolymarketDepositSourceResolver {
    private let userWalletInfo: UserWalletInfo
    private let walletModelsProvider: MainScreenUIOrderedWalletModelsProvider
    private let depositCurrencies: Set<ExpressWalletCurrency>

    init(userWalletModel: UserWalletModel, depositCurrencies: Set<ExpressWalletCurrency>) {
        userWalletInfo = userWalletModel.userWalletInfo
        walletModelsProvider = MainScreenUIOrderedWalletModelsProvider(userWalletModel: userWalletModel)
        self.depositCurrencies = depositCurrencies
    }
}

// MARK: - SwapSourceTokenResolver

extension PolymarketDepositSourceResolver: SwapSourceTokenResolver {
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

extension PolymarketDepositSourceResolver {
    static func chooseSource(
        from walletModels: [any WalletModel],
        depositCurrencies: Set<ExpressWalletCurrency>,
        userWalletInfo: UserWalletInfo
    ) -> (any WalletModel)? {
        let matching = walletModels.filter {
            depositCurrencies.contains($0.tokenItem.expressCurrency)
                && isTransferAvailable(walletModel: $0, userWalletInfo: userWalletInfo)
        }

        if let matchingSource = matching.mostFiatFundedOrFirst {
            return matchingSource
        }

        let candidates = walletModels.filter {
            TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: $0).isSwapAvailable(direction: .from)
        }
        return candidates.mostFiatFundedOrFirst
    }
}

// MARK: - Private implementation

private extension PolymarketDepositSourceResolver {
    static func isTransferAvailable(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> Bool {
        let availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)

        return SwapSourcePreselectionEligibility.canBecomeSource(for: availabilityProvider.swapSourceAvailability())
            && availabilityProvider.isSendAvailable
    }

    func resolveSourceToken(from walletModels: [any WalletModel]) -> SendSwapableToken? {
        let chosen = Self.chooseSource(
            from: walletModels,
            depositCurrencies: depositCurrencies,
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
