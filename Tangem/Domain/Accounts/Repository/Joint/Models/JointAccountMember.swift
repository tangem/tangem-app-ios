//
//  JointAccountMember.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A slot of a joint account that is taken.
struct JointAccountMember: Equatable {
    enum Role: Equatable {
        case creator
        case member
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
        case .member: .member
        }

        self.init(name: stored.name, address: stored.address, role: role)
    }
}
