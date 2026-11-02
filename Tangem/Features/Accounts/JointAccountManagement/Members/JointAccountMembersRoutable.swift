//
//  JointAccountMembersRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol JointAccountMembersRoutable: AnyObject {
    func closeMembers()
    func openAboutSignatures(policy: JointAccountPolicy)
    func openShareInviteMember(url: URL, accountName: String)
    func showInviteIssueError(_ error: Error)
    func openMemberDetails(name: String, address: String, accentColor: Color)
}
