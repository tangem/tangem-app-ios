//
//  TokenDetailsSwapPredefinedParametersBuilder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TokenDetailsSwapPredefinedParametersBuilder: SwapPredefinedParametersBuilder {
    let walletModel: any WalletModel
    let userWalletInfo: UserWalletInfo
    let direction: SwapDirection

    func make() -> PredefinedSwapParameters {
        switch direction {
        case .from:
            let sourceToken = try? makeSwapableToken(walletModel: walletModel)
            let source: any SwapSourceTokenResolver = if let sourceToken {
                .resolved(sourceToken)
            } else {
                .userSelection
            }

            return PredefinedSwapParameters(
                userWalletInfo: userWalletInfo,
                source: source,
                receive: .userSelection
            )
        case .to:
            let receiveToken = makeReceiveToken(walletModel: walletModel)
            let sourceResolver = TokenDetailsSwapSourceResolver(userWalletInfo: userWalletInfo)

            let sourceWalletModel = sourceResolver.resolveSource(for: walletModel)
            let sourceToken = sourceWalletModel.flatMap { try? makeSwapableToken(walletModel: $0) }
            let source: any SwapSourceTokenResolver = if let sourceToken {
                .resolved(sourceToken)
            } else {
                .userSelection
            }

            return PredefinedSwapParameters(
                userWalletInfo: userWalletInfo,
                source: source,
                receive: .resolved(receiveToken)
            )
        }
    }
}

// MARK: - Private

private extension TokenDetailsSwapPredefinedParametersBuilder {
    func makeReceiveToken(walletModel: any WalletModel) -> SendReceiveToken {
        WalletModelSendTokenFactory(userWalletInfo: userWalletInfo, walletModel: walletModel, operationType: .swap).makeReceiveToken()
    }

    func makeSwapableToken(walletModel: any WalletModel) throws -> SendSwapableToken {
        try WalletModelSendTokenFactory(userWalletInfo: userWalletInfo, walletModel: walletModel, operationType: .swap).makeSwapableToken()
    }
}
