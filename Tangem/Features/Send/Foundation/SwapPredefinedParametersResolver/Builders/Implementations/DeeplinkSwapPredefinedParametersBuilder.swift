//
//  DeeplinkSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct DeeplinkSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let userWalletInfo: UserWalletInfo
    let source: (any WalletModel)?
    let receive: (any WalletModel)?
    let extras: PredefinedSwapParameters.Extras?

    func make() -> PredefinedSwapParameters {
        let sourceToken = source.flatMap { try? makeSwapableToken(walletModel: $0) }
        let sourceResolver: any SwapSourceTokenResolver = if let sourceToken {
            .resolved(sourceToken)
        } else {
            .userSelection
        }

        let receiveResolver: any SwapReceiveTokenResolver = if let receive {
            .resolved(makeReceiveToken(walletModel: receive))
        } else {
            .userSelection
        }

        return PredefinedSwapParameters(
            userWalletInfo: userWalletInfo,
            source: sourceResolver,
            receive: receiveResolver,
            extras: extras
        )
    }
}

// MARK: - Private

private extension DeeplinkSwapPredefinedParametersBuilder {
    func makeReceiveToken(walletModel: any WalletModel) -> SendReceiveToken {
        WalletModelSendTokenFactory(userWalletInfo: userWalletInfo, walletModel: walletModel, operationType: .swap).makeReceiveToken()
    }

    func makeSwapableToken(walletModel: any WalletModel) throws -> SendSwapableToken {
        try WalletModelSendTokenFactory(userWalletInfo: userWalletInfo, walletModel: walletModel, operationType: .swap).makeSwapableToken()
    }
}
