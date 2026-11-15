//
//  EarnProductDetails+Common.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
extension EarnProductDetails.Detail {
    static func risk(_ level: EarnProductDetails.RiskLevel) -> EarnProductDetails.Detail {
        let value = switch level {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }

        return EarnProductDetails.Detail(value: value, info: riskInfo)
    }

    static func performanceFee(_ fee: Decimal, percentFormatter: PercentFormatter) -> EarnProductDetails.Detail {
        let feePercent = percentFormatter.format(fee, option: .performanceFee)

        return EarnProductDetails.Detail(
            value: "\(feePercent) of yield",
            info: EarnProductDetails.InfoSheet(
                title: "Performance fee",
                content: .text("\(feePercent) of the yield you earn. It is not charged on the amount you deposit.")
            )
        )
    }
}

private extension EarnProductDetails.Detail {
    static let riskInfo = EarnProductDetails.InfoSheet(
        title: "Risk information",
        content: .levels([
            EarnProductDetails.InfoSheet.Level(
                title: "Low risk",
                text: "High liquidity and shorter withdrawals. No liquidation or directional risk. Validator, protocol and smart-contract risks still apply."
            ),
            EarnProductDetails.InfoSheet.Level(
                title: "Medium risk",
                text: "High liquidity, with withdrawals targeted within 48 hours. Active management may add leverage or directional risk."
            ),
            EarnProductDetails.InfoSheet.Level(
                title: "High risk",
                text: "May use leverage and take market risk, with lower liquidity. Withdrawals can take longer and may involve slippage or counterparty risk."
            ),
        ])
    )
}
