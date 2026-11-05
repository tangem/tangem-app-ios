//
//  EarnProductDetails+PooledStaking.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

// [REDACTED_TODO_COMMENT]
extension EarnProductDetails {
    static func pooledStaking(
        performanceFee: Decimal,
        percentFormatter: PercentFormatter = PercentFormatter()
    ) -> EarnProductDetails {
        EarnProductDetails(
            benefits: [
                Benefit(
                    icon: DesignSystem.Icons.Stack.regular20,
                    title: "Yield from Ethereum itself.",
                    description: "You earn from securing the network, not from lending."
                ),
            ],
            risk: .risk(.low),
            provider: URL(string: "https://p2p.org").map { Link(title: "Validator", name: "P2P", url: $0) },
            withdrawals: Detail(
                value: "Up to 5 days",
                info: InfoSheet(
                    title: "Withdrawals",
                    content: .text("Withdrawals take up to 5 days, because Ethereum releases staked ETH through an exit queue.")
                )
            ),
            managementFee: nil,
            performanceFee: .performanceFee(performanceFee, percentFormatter: percentFormatter),
            auditReport: nil
        )
    }
}
