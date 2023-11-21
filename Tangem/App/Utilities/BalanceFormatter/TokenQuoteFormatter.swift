//
//  TokenQuoteFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PercentFormatter {
    func percentFormat(value: Decimal, option: FormattingOption = .priceChange) -> String {
        var value = value
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        switch option {
        case .priceChange:
            formatter.positivePrefix = ""
            formatter.negativePrefix = ""

            // The formatter will format value 0.12 as 12%
            // But in our case 0.12 it's 0.12%
            value /= 100
        case .expressRate:
            break
        }

        if let formatted = formatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }
}

extension PercentFormatter {
    enum FormattingOption: String {
        case priceChange
        case expressRate
    }
}
