//
//  PercentFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PercentFormatter {
    private let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    func format(_ value: Decimal, option: Option) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.maximumFractionDigits = option.fractionDigits
        formatter.minimumFractionDigits = option.fractionDigits

        formatter.negativePrefix = "-"
        formatter.positivePrefix = "+"

        formatter.positiveSuffix = " %"
        formatter.negativeSuffix = " %"

        if option.clearPrefix {
            formatter.positivePrefix = ""
            formatter.negativePrefix = ""
        }

        if let formatted = formatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }

    func formatInterval(min: Decimal, max: Decimal, option: Option) -> String {
        let minFormatter = NumberFormatter()
        minFormatter.locale = locale
        minFormatter.maximumFractionDigits = option.fractionDigits
        minFormatter.minimumFractionDigits = option.fractionDigits

        if option.clearPrefix {
            minFormatter.positivePrefix = ""
            minFormatter.negativePrefix = ""
        }

        let minFormatted = minFormatter.string(from: min as NSDecimalNumber) ?? "\(min)"
        let maxFormatted = format(max, option: option)
        return "\(minFormatted) - \(maxFormatted)"
    }
}

extension PercentFormatter {
    enum Option {
        case priceChange
        case express
        case staking

        var fractionDigits: Int {
            switch self {
            case .priceChange, .staking: 2
            case .express: 1
            }
        }

        var clearPrefix: Bool {
            switch self {
            case .priceChange, .staking: true
            case .express: false
            }
        }
    }
}
