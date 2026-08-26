//
//  EarnAccountRowData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct EarnAccountRowData: Equatable {
    let iconColor: Color
    let glyph: ImageType
    let name: String
    let tokensCountText: String
    /// Bare reward amount (the view adds "+ …/year" and masks it).
    let rewardAmount: String
}
