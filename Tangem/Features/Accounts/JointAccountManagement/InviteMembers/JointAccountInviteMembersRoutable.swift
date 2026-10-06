//
//  JointAccountInviteMembersRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol JointAccountInviteMembersRoutable: AnyObject {
    func closeInviteMembers()
    func shareInvite(url: URL, accountName: String)
    func openInviteSafety()
    /// - Parameter accentColor: The colour the member's row is drawn with, so the card opens in the one the tap
    /// came from rather than working the palette out a second time.
    func openMemberDetails(name: String, address: String, accentColor: Color)
}
