//
//  PriceValueFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PriceValueFormatter {
    private let balanceFormatter = BalanceFormatter()

    func formatValue(_ value: Decimal) -> Result {
        let formattedFiatBalance = balanceFormatter.formatFiatBalance(value)
        let formattedPrice = priceSign(value) + formattedFiatBalance
        return Result(formattedText: formattedPrice)
    }
}

// MARK: - Helpers

private extension PriceValueFormatter {
    func priceSign(_ value: Decimal) -> String {
        switch ChangeSignType(from: value) {
        case .positive: .plusSign
        case .negative, .neutral: .empty
        }
    }
}

// MARK: - Types

extension PriceValueFormatter {
    struct Result {
        let formattedText: String
    }
}
