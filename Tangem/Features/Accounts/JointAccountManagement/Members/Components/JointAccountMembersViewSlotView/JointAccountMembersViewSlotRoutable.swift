//
//  JointAccountMembersViewSlotRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol JointAccountMembersViewSlotRoutable: AnyObject {
    func shareInvite(url: URL, accountName: String)
    func openMemberDetails(name: String, address: String, accentColor: Color)
}
