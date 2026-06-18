//
//  SwapPredefinedParametersHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapPredefinedParametersHelper {
    func makeParameters(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        position: SwapDirection
    ) -> PredefinedSwapParameters? {
        switch position {
        case .automatic:
            return resolveParameters(walletModel: walletModel, userWalletInfo: userWalletInfo)
        case .from:
            let token = makeSwapableToken(walletModel: walletModel, userWalletInfo: userWalletInfo)
            return .from(token, receive: nil)
        case .to:
            let token = makeSwapableToken(walletModel: walletModel, userWalletInfo: userWalletInfo)
            return .to(token)
        }
    }
}

// MARK: - Private

private extension SwapPredefinedParametersHelper {
    func makeSwapableToken(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> SendSwapableToken {
        CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swap
        ).makeSwapableToken()
    }

    func resolveParameters(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo
    ) -> PredefinedSwapParameters? {
        let resolver = TokenDetailsSwapPairResolver(
            swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletInfo)
        )
        let resolved = resolver.resolve(walletModel: walletModel)

        if let sourceWalletModel = resolved.source {
            let sourceToken = makeSwapableToken(walletModel: sourceWalletModel, userWalletInfo: userWalletInfo)
            let destinationToken = resolved.destination.map {
                makeSwapableToken(walletModel: $0, userWalletInfo: userWalletInfo)
            }

            return .from(sourceToken, receive: destinationToken)
        }

        if let destinationWalletModel = resolved.destination {
            let destinationToken = makeSwapableToken(walletModel: destinationWalletModel, userWalletInfo: userWalletInfo)
            return .to(destinationToken)
        }

        return nil
    }
}
