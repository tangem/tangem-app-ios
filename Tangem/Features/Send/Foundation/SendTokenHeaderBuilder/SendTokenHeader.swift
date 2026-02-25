//
//  SendTokenHeader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import struct TangemAccounts.AccountIconView

enum SendTokenHeader: Hashable {
    /// In case when user has only one wallet without account
    /// We will write (You send, You stake)
    case action(name: String)

    /// Have to be name with `prefix` from
    case wallet(name: String)
    case account(prefix: String = Localization.commonFrom, name: String, icon: AccountIconView.ViewData)
}
