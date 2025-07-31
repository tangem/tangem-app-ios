//
//  MobileWalletContext.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct MobileWalletContext: Hashable {
    let walletID: UserWalletId
    let authentication: AuthenticationUnlockData
}
