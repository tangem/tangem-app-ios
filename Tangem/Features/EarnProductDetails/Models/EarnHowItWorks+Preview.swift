//
//  EarnHowItWorks+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension EarnHowItWorks {
    static let lendingOnAavePreview = EarnHowItWorks.lendingOnAave(
        performanceFee: 0.15,
        learnMoreURL: URL(string: "https://example.com/lending-on-aave")!
    )

    static let highYieldVaultPreview = EarnHowItWorks.highYieldVault(
        performanceFee: 0.15,
        withdrawalHours: 48,
        learnMoreURL: URL(string: "https://example.com/high-yield-vault")!
    )
}
