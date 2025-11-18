//
//  CryptoAccountsRemoteIdentifierBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CryptoAccountsRemoteIdentifierBuilder {
    let userWalletId: UserWalletId

    func build(from input: StoredCryptoAccount) -> String {
        let accountIdentifier = CommonCryptoAccountModel.AccountId(
            userWalletId: userWalletId,
            derivationIndex: input.derivationIndex
        )

        return accountIdentifier.rawValue.hexString
    }
}
