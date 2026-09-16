//
//  JointAccountOperationStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// How far an operation has come on the backend.
/// - Warning: Raw values are what a stored record keeps, so they cannot change silently.
enum JointAccountOperationStatus: String, Hashable, Codable {
    /// Signatures are being collected.
    case awaitingSignatures
    /// The threshold is reached and the relayer is executing.
    case pending
    case executed
    case failed
    /// One the endpoint learnt to report after this version shipped, costing the operation alone rather than the
    /// whole answer — the backend goes on adding to the set.
    case unknown

    /// Whether the operation still holds its network's slot.
    /// - Note: A stage this version does not know is not counted as holding it: the one the contract already names —
    /// `expired` — is a stage an operation is done at.
    var isInFlight: Bool {
        switch self {
        case .awaitingSignatures, .pending: true
        case .executed, .failed, .unknown: false
        }
    }
}
