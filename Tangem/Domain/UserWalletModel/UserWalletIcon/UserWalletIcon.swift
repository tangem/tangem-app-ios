//
//  UserWalletIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

enum UserWalletIcon {
    case loadable(any WalletImageProviding)
    case content(WalletIconContent)
}
