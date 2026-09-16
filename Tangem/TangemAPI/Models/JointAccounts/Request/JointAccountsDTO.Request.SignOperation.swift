//
//  JointAccountsDTO.Request.SignOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Request {
    /// The operation is named by the id in the path and the transaction is the endpoint's to look up, so the body
    /// carries nothing but the answer — a body repeating the transaction is refused.
    struct SignOperation: Encodable {
        /// EIP-712 over the operation's Safe transaction, like the one that created it.
        let signature: String
    }
}
