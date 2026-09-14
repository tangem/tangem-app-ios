//
//  JointAccountSafeAddressVerifier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

/// Checks the address the backend announces against the one the composition actually resolves to.
/// - Warning: The announced address is what the funds of the account will live at, so it is never taken on trust.
enum JointAccountSafeAddressVerifier {
    /// - Returns: The address computed from the composition, which is what gets signed once it matches.
    /// - Note: Every supported master copy is tried, since which one the backend deploys is still open — the
    /// announced address is what picks between them.
    static func confirm(
        announcedAddress: String,
        owners: [String],
        threshold: Int
    ) throws(VerificationError) -> String {
        for singleton in SafeSingleton.allCases {
            let computedAddress: String

            do {
                computedAddress = try SafeAddressUtils.compute(
                    owners: owners,
                    threshold: threshold,
                    singleton: singleton
                )
            } catch {
                // A composition no Safe can be deployed from fails the same way under every master copy, so there is
                // nothing left to try
                throw .undeployableComposition(error)
            }

            if computedAddress.caseInsensitiveCompare(announcedAddress) == .orderedSame {
                return computedAddress
            }
        }

        throw .addressMismatch
    }
}

// MARK: - Auxiliary types

extension JointAccountSafeAddressVerifier {
    enum VerificationError: Error, Equatable {
        /// The composition resolves to no address at all — see `SafeAddressUtils.ComputationError`.
        case undeployableComposition(SafeAddressUtils.ComputationError)
        /// The composition resolves to an address the backend does not name, under any supported master copy. The
        /// account is not the one it says it is, and activating would sign for someone else's Safe.
        case addressMismatch
    }
}
