//
//  ApyFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct ApyFormatter {
    func formatStaking(apy: Decimal?, rewardType: String) -> String? {
        apy.flatMap { formatInternal(apy: $0, rewardType: rewardType.uppercased()) }
    }

    func formatYieldMode(apy: Decimal?) -> String? {
        apy.flatMap { formatInternal(apy: $0 / 100, rewardType: RewardType.apr.rawValue.uppercased()) }
    }

    private func formatInternal(apy: Decimal, rewardType: String) -> String {
        let percentFormatter = PercentFormatter()
        let apyFormatted = percentFormatter.format(apy, option: .staking)
        return rewardType + " " + apyFormatted
    }
}
