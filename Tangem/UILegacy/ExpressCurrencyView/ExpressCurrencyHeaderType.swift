//
//  ExpressCurrencyHeaderType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemAccounts.AccountIconView

enum ExpressCurrencyHeaderType: Hashable {
    case action(name: String)
    case wallet(name: String)
    case account(prefix: String, name: String, icon: AccountIconView.ViewData)
}
