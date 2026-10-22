//
//  JointAccountOperation.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// An operation of a joint account as the endpoint reports it inside the account.
struct JointAccountOperation: Hashable, Identifiable, Codable {
    let id: String
    let chainId: Int
    let safeTransaction: SafeTransaction
    let status: JointAccountOperationStatus
    let txHash: String?
    /// The member who created the operation, by the address they sign with.
    let initiator: String
    /// Only the members who have answered — the rest are the account's members not listed here.
    let signatures: [Signature]
}

extension JointAccountOperation {
    struct Signature: Hashable, Codable {
        /// - Warning: Raw values are what a stored record keeps, so they cannot change silently.
        enum State: String, Hashable, Codable {
            case signed
            case declined
            /// One the endpoint learnt to report after this version shipped, costing the answer alone rather than
            /// the whole operation.
            case unknown
        }

        let address: String
        let state: State
        /// Kept as the endpoint sends it; whoever shows it decides how to read the date.
        let at: String
    }
}
