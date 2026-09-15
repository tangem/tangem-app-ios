//
//  JointAccountInvite.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// An invite the way it is handed on: by the link that carries it.
/// - Warning: The link is the invite, and the invite is the account's only access secret — see
/// `StoredJointAccountInvite`.
struct JointAccountInvite: Equatable {
    let id: String
    let url: URL
}
