//
//  EarnTokenRowData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct EarnTokenRowData: Identifiable, Equatable {
    let id: String
    let tokenIconInfo: TokenIconInfo
    let name: String
    let network: String
    let rewardText: String
    let apyText: String
}
