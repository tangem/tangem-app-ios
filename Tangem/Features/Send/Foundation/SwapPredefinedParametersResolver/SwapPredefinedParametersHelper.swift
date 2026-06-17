//
//  SwapPredefinedParametersHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapPredefinedParametersHelper {
    func makeParameters(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> PredefinedSwapParameters? {
        resolveParameters(walletModel: walletModel, userWalletInfo: userWalletInfo)
    }
}

// MARK: - Private

private extension SwapPredefinedParametersHelper {
    func resolveParameters(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo
    ) -> PredefinedSwapParameters? {
        let resolver = TokenDetailsSwapPairResolver(
            swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletInfo)
        )
        let resolved = resolver.resolve(walletModel: walletModel)

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

            return .from(sourceToken, receive: destinationToken)
        }

        if let destinationWalletModel = resolved.destination {
            let destinationToken = CommonSendSwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                walletModel: destinationWalletModel,
                operationType: .swap
            ).makeSwapableToken()

            return .to(destinationToken)
        }

        return nil
    }
}
