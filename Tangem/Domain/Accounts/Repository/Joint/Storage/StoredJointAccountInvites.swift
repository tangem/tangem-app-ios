//
//  StoredJointAccountInvites.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The invites a wallet was handed for one of its joint accounts, kept apart from the account itself so that reading
/// the list of accounts back cannot take them along.
/// - Note: A list of these rather than a dictionary keyed by the identifier: `cryptoAccountId` is matched without
/// regard to its case everywhere else, which a dictionary key cannot do.
struct StoredJointAccountInvites: Codable, Equatable {
    let cryptoAccountId: String
    /// Empty when the account was created with every slot taken, which is not the same as having no record at all.
    let invites: [JointAccountInvite]
}
