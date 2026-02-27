//
//  AverageRewardingViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct AverageRewardingViewData: Hashable, Identifiable {
    var id: Int { hashValue }

    let rewardType: String
    let rewardFormatted: String

    let periodProfitFormatted: String
    let profitFormatted: LoadableTextView.State
}
