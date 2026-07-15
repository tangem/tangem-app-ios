//
//  SummaryGaugeAsset.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct SummaryGaugeAsset: Identifiable {
    let id: UUID
    let name: String
    let fiatValue: Decimal
}
