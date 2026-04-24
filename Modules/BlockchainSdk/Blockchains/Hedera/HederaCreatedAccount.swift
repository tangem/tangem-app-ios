//
//  HederaCreatedAccount.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct HederaCreatedAccount: CreatedAccount {
    let accountId: String

    public init(accountId: String) {
        self.accountId = accountId
    }
}
