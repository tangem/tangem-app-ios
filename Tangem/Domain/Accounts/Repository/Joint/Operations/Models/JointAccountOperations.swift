//
//  JointAccountOperations.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The operations of one joint account.
/// - Note: A list of these rather than a dictionary keyed by the identifier: `cryptoAccountId` is matched without
/// regard to its case everywhere else, which a dictionary key cannot do.
struct JointAccountOperations: Equatable {
    let cryptoAccountId: String
    /// Never empty: an account with no operations has no record at all.
    let operations: [JointAccountOperation]
}

// MARK: - Convenience

extension JointAccountOperations {
    /// - Returns: `nil` for an account the listing reported no operations for, which has no record to keep.
    init?(remote: RemoteJointAccount) {
        guard !remote.operations.isEmpty else {
            return nil
        }

        self.init(cryptoAccountId: remote.cryptoAccountId, operations: remote.operations)
    }
}
