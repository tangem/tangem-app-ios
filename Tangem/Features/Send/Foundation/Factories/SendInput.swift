//
//  SendInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendInput {
    let userWalletInfo: UserWalletInfo
    // [REDACTED_TODO_COMMENT]
    let account: (any CryptoAccountModel)?
    let walletModel: any WalletModel

    init(
        userWalletInfo: UserWalletInfo,
        account: (any CryptoAccountModel)? = .none,
        walletModel: any WalletModel
    ) {
        self.userWalletInfo = userWalletInfo
        self.account = account
        self.walletModel = walletModel
    }
}
