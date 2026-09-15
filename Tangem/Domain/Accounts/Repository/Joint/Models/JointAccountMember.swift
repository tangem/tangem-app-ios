//
//  JointAccountMember.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A slot of a joint account that is taken.
struct JointAccountMember: Equatable {
    /// Which slot this is, and — for everyone the creator let in — the invite it was taken with. The creator never
    /// has one: they opened the account rather than being invited into it. A member has one only while the endpoint
    /// still reports it, which is until the account is activated: once every slot is filled the invites have served
    /// their purpose and an active account is described without them.
    enum Role: Equatable {
        case creator
        case member(inviteId: String?)
    }

    /// From 1 to 25 characters.
    let name: String
    /// The address this member is derived at for this account, which is what the other members know them by and what
    /// their signature of an operation is checked against. Not an address of anything they hold elsewhere.
    /// - Warning: The endpoint keeps these in lower case while the app computes the checksummed form, so two of
    /// these are only ever compared case-insensitively, never as strings.
    let address: String
    let role: Role
}

// MARK: - Convenience

extension JointAccountMember {
    init(stored: StoredJointAccount.Member) {
        let role: Role = switch stored.role {
        case .creator: .creator
        case .member: .member(inviteId: stored.inviteId)
        }

        self.init(name: stored.name, address: stored.address, role: role)
    }
}

extension JointAccountMember.Role {
    var inviteId: String? {
        switch self {
        case .creator: nil
        case .member(let inviteId): inviteId
        }
    }
}
