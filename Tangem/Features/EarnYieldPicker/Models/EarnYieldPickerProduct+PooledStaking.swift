//
//  EarnYieldPickerProduct+PooledStaking.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
extension EarnYieldPickerProduct {
    static func pooledStaking(apy: Decimal, performanceFee: Decimal) -> EarnYieldPickerProduct {
        EarnYieldPickerProduct(
            id: .pooledStaking,
            name: "Pooled staking",
            apy: apy,
            incentiveApy: nil,
            performanceFee: performanceFee,
            description: "Earn variable yield on ETH by staking with P2P, a professional validator that helps secure Ethereum. Withdrawals take up to 5 days, and a small risk of loss applies if the validator is penalised by the network.",
            details: .pooledStaking(performanceFee: performanceFee)
        )
    }
}
