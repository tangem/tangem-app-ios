//
//  YieldTokenInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct YieldModuleTokenInfo: Codable, Equatable {
    let isActive: Bool
    let apy: Decimal
    let maxFeeNative: Decimal
    let maxFeeUSD: Decimal
}
