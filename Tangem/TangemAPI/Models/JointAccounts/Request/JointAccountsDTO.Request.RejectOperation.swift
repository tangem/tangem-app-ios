//
//  JointAccountsDTO.Request.RejectOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension JointAccountsDTO.Request {
    /// Cancelling by the initiator and declining by a co-signer are one and the same request: which of the two it is,
    /// the endpoint works out from the address the signature recovers to. Signed the way the account requests are —
    /// EIP-191 over the canonical payload — deliberately not EIP-712 over the SafeTx, which would read as an approval.
    struct RejectOperationPayload: Encodable {
        /// Repeats the id in the path so the signature covers it.
        let operationId: String
        /// The whole transaction, for the endpoint to check against what it holds.
        let safeTx: JointAccountsDTO.SafeTx
    }

    typealias RejectOperation = SignedRequest<RejectOperationPayload>
}
