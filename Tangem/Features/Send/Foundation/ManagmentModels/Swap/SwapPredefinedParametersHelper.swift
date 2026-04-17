//
//  SwapPredefinedParametersHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapPredefinedParametersHelper {
    /// Simple swap parameters — source is the given wallet model, no resolver logic.
    func makeFromParameters(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> PredefinedSwapParameters {
        let sourceToken = CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swap
        ).makeSwapableToken()

        return .from(sourceToken)
    }

    /// Resolved swap parameters — uses `CommonSwapTokenPairResolver` to pick the best source/destination pair.
    func makeResolvedParameters(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> PredefinedSwapParameters {
        let resolver = CommonSwapTokenPairResolver()
        let resolved = resolver.resolve(for: .tokenDetails(.init(walletModel: walletModel)))

        if let sourceWalletModel = resolved.source {
            let sourceToken = CommonSendSwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                walletModel: sourceWalletModel,
                operationType: .swap
            ).makeSwapableToken()

            let destinationToken = resolved.destination.map {
                CommonSendSwapableTokenFactory(
                    userWalletInfo: userWalletInfo,
                    walletModel: $0,
                    operationType: .swap
                ).makeSwapableToken()
            }

            return .pair(source: sourceToken, receive: destinationToken)
        }

        if let destinationWalletModel = resolved.destination {
            let destinationToken = CommonSendSwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                walletModel: destinationWalletModel,
                operationType: .swap
            ).makeSwapableToken()

            return .to(destinationToken)
        }

        // Fallback: use the original wallet model as source
        return makeFromParameters(walletModel: walletModel, userWalletInfo: userWalletInfo)
    }
}
