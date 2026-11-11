//
//  JointAccountConfirmationSignatureVerifier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

enum JointAccountConfirmationSignatureVerifier {
    static func allMembersConfirmed(
        config: JointAccountSignedConfig,
        safeAddress: String,
        members: [StoredJointAccount.Member]
    ) -> Bool {
        guard members.count == config.membersCount else {
            return false
        }

        do {
            let digest = try JointAccountDerivationUtils.digest(
                payload: JointAccountConfirmationPayload(config: config, safeAddress: safeAddress)
            )

            return try members.allSatisfy { member in
                guard let signature = member.signature else {
                    return false
                }

                return try JointSafeSignatureRecoverer.recoverSigner(ofDigest: digest, signature: signature).caseInsensitiveEquals(to: member.address)
            }
        } catch {
            JointAccountsLogger.error("Unable to verify a joint account's confirmation signatures", error: error)
            return false
        }
    }
}
