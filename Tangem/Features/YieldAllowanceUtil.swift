//
//  YieldAllowanceUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct YieldAllowanceUtil {
    func isPermissionRequired(allowance: String) -> Bool {
        BigUInt(Data(hexString: allowance)) < Constants.maxAllowance / 2
    }
}

extension YieldAllowanceUtil {
    enum Constants {
        static let maxAllowance = BigUInt(2).power(256) - 1
    }
}
