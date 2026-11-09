//
//  JointAccountIssuedInvite.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountIssuedInvite: Equatable {
    let id: String
    let slot: JointAccountMemberSlotID
    let expiresAt: Date
}
