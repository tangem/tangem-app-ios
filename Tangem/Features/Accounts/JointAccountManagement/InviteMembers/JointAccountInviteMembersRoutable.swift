//
//  JointAccountInviteMembersRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountInviteMembersRoutable: AnyObject {
    func closeInviteMembers()
    func shareInvite(url: URL)
    func openInviteSafety()
    func openMemberDetails(member: JointAccountMember)
}
