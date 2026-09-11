//
//  JointAccountMemberRole.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - Note: The creator is a member as well: they take the first slot, and inviting and activating are theirs alone.
/// - Warning: Raw values are what the endpoint reports and what a stored record keeps, so they cannot change silently.
enum JointAccountMemberRole: String, Codable, Equatable {
    case creator
    case member
}
