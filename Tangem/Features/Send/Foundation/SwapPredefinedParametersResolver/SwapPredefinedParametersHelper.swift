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
    ) -> PredefinedSwapParameters {
        switch position {
        case .from:
            let token = makeSwapableToken(walletModel: walletModel, userWalletInfo: userWalletInfo)
            return .from(token)
        case .to:
            let receiveToken = makeReceiveToken(walletModel: walletModel, userWalletInfo: userWalletInfo)
            let sourceResolver = TokenDetailsSwapSourceResolver(
                swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletInfo)
            )

            guard let sourceWalletModel = sourceResolver.resolveSource(for: walletModel) else {
                return .to(receiveToken)
            }

            let sourceToken = makeSwapableToken(walletModel: sourceWalletModel, userWalletInfo: userWalletInfo)
            return .from(sourceToken, pair: .fixed(receive: receiveToken))
        }
    }

    func makeParameters(
        fromWalletModel: any WalletModel,
        toWalletModel: (any WalletModel)?,
        userWalletInfo: UserWalletInfo,
        extras: PredefinedSwapParameters.Extras?
    ) -> PredefinedSwapParameters {
        let source = makeSwapableToken(walletModel: fromWalletModel, userWalletInfo: userWalletInfo)
        let receive = toWalletModel.map { makeReceiveToken(walletModel: $0, userWalletInfo: userWalletInfo) }
        return .from(source, pair: .fixed(receiveOrUserSelection: receive), extras: extras)
    }
}

// MARK: - Private

private extension SwapPredefinedParametersHelper {
    func makeReceiveToken(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> SendSourceToken {
        if walletModel.isJointAccountParticipant {
            return CommonSendSourceTokenFactory(userWalletInfo: userWalletInfo, walletModel: walletModel).makeSourceToken()
        }

        return makeSwapableToken(walletModel: walletModel, userWalletInfo: userWalletInfo)
    }

    func makeSwapableToken(walletModel: any WalletModel, userWalletInfo: UserWalletInfo) -> SendSwapableToken {
        CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swap
        ).makeSwapableToken()
    }
}
