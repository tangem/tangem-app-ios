//
//  JointAccountMembersCountRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol JointAccountMembersCountRoutable: AnyObject {
    func closeMembersCount()
    func continueMembersCount(creationContext: JointAccountCreationHelper)
}
