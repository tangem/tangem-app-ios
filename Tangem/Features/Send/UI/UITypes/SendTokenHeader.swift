//
//  SendTokenHeader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemAccounts.AccountIconView

enum SendTokenHeader: Hashable {
    // In case when user has only one wallet without account
    // We will write (You send, You stake)
    case action(name: String)
    case wallet(name: String)
    case account(name: String, icon: AccountIconView.ViewData)
}
