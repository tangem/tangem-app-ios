//
//  JointAccountJoinPayload.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - Warning: Canonicalised and verified the same way `JointAccountCreationPayload` is.
struct JointAccountJoinPayload: Codable, Equatable {
    /// Which invite is being spent. Whoever holds it takes the slot, so it never leaves the request.
    let inviteId: String
    /// What the invite reported, carried through untouched. The endpoint compares it against the account and refuses
    /// the two if they differ, which is what stops an invite from promising settings the account does not have.
    let config: JointAccountSignedConfig
    let member: JointAccountSignedMember
}
