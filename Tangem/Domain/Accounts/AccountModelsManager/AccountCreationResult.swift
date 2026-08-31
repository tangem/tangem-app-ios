//
//  AccountCreationResult.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct AccountCreationResult {
    let operationResult: AccountOperationResult
    /// The identity the account was created under — minted from the remote state fetched within the same call
    /// and baked into the creation request, which is what makes it safe to look the created model up by.
    let derivationIdentity: CryptoAccountDerivationIdentity
}
