//
//  EarnHowItWorks+LendingOnAave.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
extension EarnHowItWorks {
    static func lendingOnAave(
        performanceFee: Decimal,
        learnMoreURL: URL,
        percentFormatter: PercentFormatter = PercentFormatter()
    ) -> EarnHowItWorks {
        let feePercent = percentFormatter.format(performanceFee, option: .performanceFee)

        return EarnHowItWorks(
            steps: [
                Step(
                    title: "You choose the amount",
                    description: "Pick how much ETH to lend. The rest stays in your wallet, untouched."
                ),
                Step(
                    title: "Your money starts working",
                    description: "Any interest you receive is compounded. Nothing to manage"
                ),
                Step(
                    title: "Watch it grow",
                    description: "Your deposit balance grows continuously as you earn interest. We keep \(feePercent) of what it earns, never your own money"
                ),
                Step(
                    title: "Take it back anytime",
                    description: "Withdrawals are usually instant, subject to available Aave liquidity."
                ),
            ],
            attribution: Attribution(text: "Contract audited by Pessimistic", highlighted: "Pessimistic"),
            learnMoreURL: learnMoreURL
        )
    }
}
