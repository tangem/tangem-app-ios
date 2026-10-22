//
//  TokenSelectorItemOutputTypeBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct TokenSelectorItemOutputTypeBuilder {
    let expressOperationType: ExpressOperationType

    func makeReceiveToken(item: TokenSelectorItem) throws -> SendReceiveToken {
        switch item.kind {
        case .crypto(let walletModel, _):
            return WalletModelSendTokenFactory(
                userWalletInfo: item.userWalletInfo,
                walletModel: walletModel,
                operationType: expressOperationType
            ).makeReceiveToken()

        case .tangemPay:
            return try makeSwapableToken(item: item)
        }
    }

    func makeSwapableToken(item: TokenSelectorItem) throws -> SendSwapableToken {
        switch item.kind {
        case .crypto(let walletModel, _):
            return try WalletModelSendTokenFactory(
                userWalletInfo: item.userWalletInfo,
                walletModel: walletModel,
                operationType: expressOperationType
            ).makeSwapableToken()

        case .tangemPay(let tangemPayAccount, let accountToken, let account):
            return TangemPaySwapableTokenFactory(
                userWalletInfo: item.userWalletInfo,
                tangemPayAccount: tangemPayAccount,
                account: account,
                accountToken: accountToken,
                operationType: expressOperationType,
                receiveTokenPresentation: .tangemPayAccount
            ).makeSwapableToken()
        }
    }
}
