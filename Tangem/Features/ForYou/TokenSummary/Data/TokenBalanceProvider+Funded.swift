//
//  TokenBalanceProvider+Funded.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension TokenBalanceProvider {
    var isFunded: Bool { (balanceType.value ?? 0) > 0 }
}
