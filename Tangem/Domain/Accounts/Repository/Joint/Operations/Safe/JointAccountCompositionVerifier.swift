//
//  JointAccountCompositionVerifier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

/// Checks that the Safe on chain is still the account the members agreed to before anything is signed for it.
struct JointAccountCompositionVerifier {
    /// - Parameter memberAddresses: The addresses the account's members sign with, in any case.
    func verify(state: SafeContractState, safeAddress: String, memberAddresses: [String], signersCount: Int) throws {
        switch state {
        case .notDeployed:
            // Nothing on chain to read yet, so the address is the composition: it is what CREATE2 gives these
            // members and this threshold, and the operation being signed is what deploys the Safe to it
            do {
                _ = try JointAccountSafeAddressVerifier.confirm(
                    announcedAddress: safeAddress,
                    owners: memberAddresses,
                    threshold: signersCount
                )
            } catch {
                JointAccountsLogger.error("The Safe of a joint account does not resolve to the composition it is operated by", error: error)
                throw JointOperationError.compositionMismatch
            }
        case .deployed(_, let owners, let threshold):
            let ownersOnChain = owners.map { $0.lowercased() }.toSet()
            let members = memberAddresses.map { $0.lowercased() }.toSet()

            guard ownersOnChain == members, threshold == signersCount else {
                throw JointOperationError.compositionMismatch
            }
        }
    }
}
