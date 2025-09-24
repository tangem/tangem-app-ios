//
//  YieldModuleMarketInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct YieldModuleMarketInfo: Codable, Equatable {
    let tokenContractAddress: String
    let apy: Decimal
    let isActive: Bool
}
