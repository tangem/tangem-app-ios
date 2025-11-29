//
//  UserWalletModel+UserWalletInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension UserWalletInfoProvider where Self: UserWalletModel {
    var userWalletInfo: UserWalletInfo {
        UserWalletInfo(
            name: name,
            id: userWalletId,
            config: config,
            refcode: refcodeProvider?.getRefcode(),
            signer: signer,
            emailDataProvider: self
        )
    }
}
