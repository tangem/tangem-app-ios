//
//  YieldAllowanceUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk

struct YieldAllowanceUtil {
    func isPermissionRequired(allowance: String) -> Bool {
        BigUInt(Data(hexString: allowance)) < BigUInt.maxUInt256 / 2
    }
}
