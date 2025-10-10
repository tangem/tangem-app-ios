//
//  SendWalletInfo.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

struct SendWalletInfo {
    let name: String
    let id: UserWalletId
    let config: UserWalletConfig
    let signer: any TangemSigner
    let emailDataProvider: any EmailDataProvider
}

extension UserWalletModel {
    var sendWalletInfo: SendWalletInfo {
        .init(
            name: name,
            id: userWalletId,
            config: config,
            signer: signer,
            emailDataProvider: self
        )
    }
}
