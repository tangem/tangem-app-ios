//
//  JointAccountsDTO.Request.SignOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Request {
    /// The operation is named by the id in the path, but the transaction travels with the answer all the same: the
    /// endpoint checks the signature against the body it was sent and the body against the one it holds.
    struct SignOperation: Encodable {
        /// The whole transaction, worded exactly as the operation was created with.
        let safeTx: JointAccountsDTO.SafeTx
        /// EIP-712 over the Safe transaction above, like the one that created the operation.
        let signature: String
    }
}
