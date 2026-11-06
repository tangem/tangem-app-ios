//
//  EarnWithdrawalResultContentView+Preview.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension EarnWithdrawalResultContentView.StateModel {
    static func preview(status: EarnWithdrawalResultContentView.Status, withdrawalPeriod: String) -> Self {
        Self(
            status: status,
            title: status == .withdrawn ? "Withdrawn 0.5 ETH" : "Withdrawal in progress\n0.5 ETH",
            summary: "$2,130.88 · 2 May 2024 at 9:41",
            withdrawalPeriod: withdrawalPeriod,
            fee: EarnWithdrawalResultContentView.Fee(symbol: "USDT", value: "$1.40"),
            hasTransactionLink: true
        )
    }
}
