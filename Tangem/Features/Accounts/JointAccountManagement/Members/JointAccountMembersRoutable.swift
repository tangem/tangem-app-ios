//
//  JointAccountMembersRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol JointAccountMembersRoutable: AnyObject {
    func closeMembers()
    func openAboutSignatures(policy: JointAccountPolicy)
}
