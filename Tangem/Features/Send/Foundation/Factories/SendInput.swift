//
//  SendInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct SendInput {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel
    let expressInput: CommonExpressDependenciesFactory.Input

    init(
        userWalletInfo: UserWalletInfo,
        walletModel: any WalletModel,
        expressInput: CommonExpressDependenciesFactory.Input
    ) {
        self.userWalletInfo = userWalletInfo
        self.walletModel = walletModel
        self.expressInput = expressInput
    }
}
