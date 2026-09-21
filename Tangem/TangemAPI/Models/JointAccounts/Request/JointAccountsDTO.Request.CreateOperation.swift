//
//  JointAccountsDTO.Request.CreateOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Request {
    /// No payload envelope here, unlike the account requests: the signature is EIP-712 over the SafeTx within the
    /// `{chainId, verifyingContract: safeAddress}` domain rather than EIP-191 over a canonical payload, and it
    /// counts as the initiator's own — the first one collected.
    struct CreateOperation: Encodable {
        /// The address from the signature's domain.
        let safeAddress: String
        let chainId: Int
        let safeTx: JointAccountsDTO.SafeTx
        /// `0x` followed by 130 hex characters.
        let signature: String
    }
}
