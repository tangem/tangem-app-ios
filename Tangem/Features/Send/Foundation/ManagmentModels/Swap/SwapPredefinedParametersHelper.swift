//
//  SwapPredefinedParametersHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SwapPredefinedParametersHelper {
    func makeParameters(origin: SwapPairResolvingOrigin, userWalletInfo: UserWalletInfo) -> PredefinedSwapParameters? {
        switch origin {
        case .tokenDetails(let input):
            if FeatureProvider.isAvailable(.swapPipelineV2) {
                return resolveParameters(for: origin, userWalletInfo: userWalletInfo)
            }

            return makeFromParameters(walletModel: input.walletModel, userWalletInfo: userWalletInfo)

        case .markets(let input):
            if FeatureProvider.isAvailable(.swapPipelineV2) {
                return resolveParameters(for: origin, userWalletInfo: userWalletInfo)
            }

            return makeToParameters(walletModel: input.walletModel, userWalletInfo: userWalletInfo)

        case .mainScreen:
            if FeatureProvider.isAvailable(.swapPipelineV2) {
                return resolveParameters(for: origin, userWalletInfo: userWalletInfo)
            }

            return nil
        }
    }
}

// MARK: - Private

private extension SwapPredefinedParametersHelper {
    func makeToParameters(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> PredefinedSwapParameters {
        let receiveToken = CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swap
        ).makeSwapableToken()

        return .to(receiveToken)
    }

    func makeFromParameters(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> PredefinedSwapParameters {
        let sourceToken = CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swap
        ).makeSwapableToken()

        return .from(sourceToken)
    }

    func resolveParameters(
        for origin: SwapPairResolvingOrigin,
        userWalletInfo: UserWalletInfo
    ) -> PredefinedSwapParameters? {
        let resolver = CommonSwapTokenPairResolver(
            swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletInfo)
        )
        let resolved = resolver.resolve(for: origin)

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
