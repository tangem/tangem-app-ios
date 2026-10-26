//
//  YieldModePromoSheetData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct YieldModePromoSheetData: Equatable {
    let apy: Decimal
    let tokensCount: Int
    let tokenSymbol: String
    let blockchainName: String
}
