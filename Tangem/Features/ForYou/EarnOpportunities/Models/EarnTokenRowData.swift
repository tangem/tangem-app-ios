//
//  EarnTokenRowData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnTokenRowData: Identifiable, Equatable {
    let id: String
    let name: String
    let network: String
    let rewardText: String
    let apyPercent: String
}
