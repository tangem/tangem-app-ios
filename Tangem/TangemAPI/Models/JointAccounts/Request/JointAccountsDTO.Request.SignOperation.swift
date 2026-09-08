//
//  JointAccountsDTO.Request.SignOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Request {
    /// The whole transaction travels again rather than being referenced: the endpoint verifies the signature against
    /// what arrived and only then checks it matches what it holds.
    struct SignOperation: Encodable {
        let safeTx: JointAccountsDTO.SafeTx
        /// EIP-712 over `safeTx`, like the one that created the operation.
        let signature: String
    }
}
