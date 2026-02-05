//
//  TangemAccounts.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct TangemAccounts.AccountIconView

enum ExpressInteractorTokenHeader: Hashable {
    case wallet(name: String)
    case account(name: String, icon: AccountIconView.ViewData)
}
