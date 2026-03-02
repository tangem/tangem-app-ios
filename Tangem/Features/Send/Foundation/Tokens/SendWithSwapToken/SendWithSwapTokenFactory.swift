//
//  SendWithSwapTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct SendWithSwapTokenFactory {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel

    func makeWithSwapToken() -> SendWithSwapToken {
        let transferableTokenFactory = CommonSendTransferableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )
        let transferableToken = transferableTokenFactory.makeTransferableToken()

        let swapableTokenFactory = CommonSendSwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel,
            operationType: .swapAndSend
        )
        let swapableToken = swapableTokenFactory.makeSwapableToken()

        return CommonSendWithSwapToken(
            transferableToken: transferableToken,
            swapableToken: swapableToken
        )
    }
}
