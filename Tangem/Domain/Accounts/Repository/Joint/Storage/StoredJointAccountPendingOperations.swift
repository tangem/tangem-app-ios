//
//  StoredJointAccountPendingOperations.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The unfinished operations of one joint account, as the listing last reported them. Kept apart from the account
/// because an operation moves on its own occasions — a co-signer answers, the relayer executes — and none of them is
/// a change to the account it belongs to.
/// - Note: A list of these rather than a dictionary keyed by the identifier: `cryptoAccountId` is matched without
/// regard to its case everywhere else, which a dictionary key cannot do.
struct StoredJointAccountPendingOperations: Codable, Equatable {
    let cryptoAccountId: String
    /// Never empty: an account the listing reported nothing for has no record here at all.
    /// - Note: Everything the listing carried, whatever stage it names — the listing dropping an operation is what
    /// ends it, and which of them are worth showing is for whoever shows them to decide.
    let operations: [JointAccountOperation]
}

// MARK: - Convenience

extension StoredJointAccountPendingOperations {
    /// - Returns: `nil` for an account the listing reported no operations for, which has no record to keep.
    init?(remote: RemoteJointAccount) {
        guard !remote.operations.isEmpty else {
            return nil
        }

        self.init(cryptoAccountId: remote.cryptoAccountId, operations: remote.operations)
    }
}
