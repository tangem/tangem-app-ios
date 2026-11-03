//
//  EarnYieldPickerProduct+LendingOnAave.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
extension EarnYieldPickerProduct {
    static func lendingOnAave(
        apy: Decimal,
        incentiveApy: Decimal?,
        performanceFee: Decimal,
        auditReportURL: URL
    ) -> EarnYieldPickerProduct {
        EarnYieldPickerProduct(
            id: .lendingOnAave,
            name: "Lending on Aave",
            apy: apy,
            incentiveApy: incentiveApy,
            performanceFee: performanceFee,
            description: "Earn variable yield on ETH by lending it directly on Aave, an on-chain self-custodial lending protocol. Withdrawals are usually instant.",
            details: .lendingOnAave(performanceFee: performanceFee, auditReportURL: auditReportURL)
        )
    }
}
