//
//  XPUBInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct XPUBInfo {
    let addresses: [Address]
}

extension XPUBInfo {
    struct Address {
        let address: String
        let derivationPath: DerivationPath
        let transfers: Int
        let balance: Decimal

        var isUsed: Bool { transfers > 0 }
    }
}
