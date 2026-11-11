//
//  YieldTokenInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct YieldModuleTokenInfo {
    let apy: Decimal
}

extension YieldModuleTokenInfo {
    init(dto: YieldModuleDTO.Response.PositionInfo) {
        self.init(apy: dto.apy / 100)
    }
}
