//
//  SummaryGaugeAsset.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import struct SwiftUI.Color

struct SummaryGaugeAsset: Identifiable, Equatable {
    let id: String
    let name: String
    let fiatValue: Decimal
    let segmentColor: Color?
}
