//
//  JointAccountMember.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A slot of a joint account that is taken.
struct JointAccountMember: Equatable {
    /// From 1 to 25 characters.
    let name: String
    /// The address this member is derived at for this account, which is what the other members know them by and what
    /// their signature of an operation is checked against. Not an address of anything they hold elsewhere.
    /// - Warning: Its letter case carries an EIP-55 checksum rather than identity, so two of these are never
    /// compared as strings.
    let address: String
    let role: JointAccountMemberRole
}
