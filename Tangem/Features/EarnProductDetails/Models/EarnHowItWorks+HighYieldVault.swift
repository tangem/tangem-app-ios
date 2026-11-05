//
//  EarnHowItWorks+HighYieldVault.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
extension EarnHowItWorks {
    static func highYieldVault(
        performanceFee: Decimal,
        withdrawalHours: Int,
        learnMoreURL: URL,
        percentFormatter: PercentFormatter = PercentFormatter()
    ) -> EarnHowItWorks {
        let feePercent = percentFormatter.format(performanceFee, option: .performanceFee)

        return EarnHowItWorks(
            steps: [
                Step(
                    title: "Deposit once",
                    description: "One tap of your card. Gauntlet takes it from there"
                ),
                Step(
                    title: "Professionally curated",
                    description: "Gauntlet runs an audited ETH strategy with strict risk limits. Your ETH stays ETH"
                ),
                Step(
                    title: "Watch it grow",
                    description: "The rate you see is net. A \(feePercent) performance fee is already taken out"
                ),
                Step(
                    title: "Always yours",
                    description: "Self-custodial. Your assets stay on-chain and only your card can move them"
                ),
                Step(
                    title: "Take it back anytime",
                    description: "Withdraw whenever you like. It completes within \(withdrawalHours) hours"
                ),
            ],
            attribution: Attribution(text: "Audited strategy curated by Gauntlet", highlighted: "Gauntlet"),
            learnMoreURL: learnMoreURL
        )
    }
}
