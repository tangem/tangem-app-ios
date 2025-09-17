//
//  CommonCryptoAccountModelBasedRemoteIdentifierBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

/// Implements the `CryptoAccountsRemoteIdentifierBuilding` interface using
/// underlying logic from the `CommonCryptoAccountModel.AccountId` domain model.
struct CommonCryptoAccountModelBasedRemoteIdentifierBuilder {
    let userWalletId: UserWalletId
}

// MARK: - CryptoAccountsRemoteIdentifierBuilding protocol conformance

extension CommonCryptoAccountModelBasedRemoteIdentifierBuilder: CryptoAccountsRemoteIdentifierBuilding {
    func build(from input: StoredCryptoAccount) -> String {
        let accountIdentifier = CommonCryptoAccountModel.AccountId(
            userWalletId: userWalletId,
            derivationIndex: input.derivationIndex
        )

        return accountIdentifier.rawValue.hexString
    }
}
