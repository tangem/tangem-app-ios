//
//  JointAccountStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Only ever moves forward.
/// - Warning: Raw values are what the endpoint reports and what a stored record keeps, so they cannot change silently.
enum JointAccountStatus: String, Codable, Equatable {
    /// No address until every slot is taken.
    case pending
    /// Every slot taken and the address computed; the members check it and the creator activates.
    case confirming
    case active
}
