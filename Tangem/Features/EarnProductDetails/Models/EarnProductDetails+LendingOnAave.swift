//
//  EarnProductDetails+LendingOnAave.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

// [REDACTED_TODO_COMMENT]
extension EarnProductDetails {
    static func lendingOnAave(
        performanceFee: Decimal,
        auditReportURL: URL,
        percentFormatter: PercentFormatter = PercentFormatter()
    ) -> EarnProductDetails {
        EarnProductDetails(
            benefits: [
                Benefit(
                    icon: DesignSystem.Icons.Lightning.regular20,
                    title: "No lock-ups.",
                    description: "Send, swap, or sell your funds instantly, anytime you want"
                ),
                Benefit(
                    icon: DesignSystem.Icons.ArrowRefresh.regular20,
                    title: "Withdraw anytime.",
                    description: "Aave's deep liquidity means your ETH is available on demand, subject to protocol liquidity"
                ),
            ],
            risk: .risk(.low),
            provider: Link(title: "Protocol", name: "Aave", url: URL(string: "https://aave.com")!),
            withdrawals: Detail(
                value: "Usually instant",
                info: InfoSheet(
                    title: "Withdrawals",
                    content: .text("Withdrawals are usually instant. They depend on the ETH available in Aave, so if liquidity is low, you can withdraw up to the available amount and the rest once liquidity returns.")
                )
            ),
            managementFee: nil,
            performanceFee: .performanceFee(performanceFee, percentFormatter: percentFormatter),
            auditReport: Link(title: "Audits", name: "Reports", url: auditReportURL)
        )
    }
}
