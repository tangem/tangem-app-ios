//
//  EarnYieldPickerProduct+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension EarnYieldPickerProduct {
    static let lendingOnAavePreview = EarnYieldPickerProduct.lendingOnAave(
        apy: 0.03,
        incentiveApy: 0.014,
        performanceFee: 0.15,
        auditReportURL: URL(string: "https://example.com/audit-report")
    )

    static let pooledStakingPreview = EarnYieldPickerProduct.pooledStaking(apy: 0.02, performanceFee: 0.08)
}
