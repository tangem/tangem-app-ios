//
//  CommonMarketCapFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonMarketCapFormatter {
    static var defaultEmptyBalanceString: String { "–" }

    /// Format any decimal number using `BalanceFormattingOptions`
    /// - Note: Balance will be rounded using `roundingType` from `formattingOptions`
    /// - Parameters:
    ///   - value: Balance that should be rounded and formatted
    ///   - formattingOptions: Options for number formatter and rounding
    /// - Returns: Formatted balance string, if `value` is nil, returns `defaultEmptyBalanceString`
    func formatDecimal(_ value: Decimal?, formattingOptions: Options = .default) -> String {
        guard let value else {
            return Self.defaultEmptyBalanceString
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = formattingOptions.minFractionDigits
        formatter.maximumFractionDigits = formattingOptions.maxFractionDigits

        let valueToFormat = roundDecimal(value, with: formattingOptions.roundingType)
        return formatter.string(from: valueToFormat as NSDecimalNumber) ?? "\(valueToFormat)"
    }

    // MARK: - Private Implementation

    private func roundDecimal(_ value: Decimal, with roundingType: AmountRoundingType?) -> Decimal {
        if value == 0 {
            return 0
        }

        guard let roundingType = roundingType else {
            return value
        }

        switch roundingType {
        case .shortestFraction(let roundingMode):
            return SignificantFractionDigitRounder(roundingMode: roundingMode).round(value: value)
        case .default(let roundingMode, let scale):
            return max(value, Decimal(1) / pow(10, scale)).rounded(scale: scale, roundingMode: roundingMode)
        }
    }

    private func formatPoints(_ value: Decimal) -> String {
        let thousandNum = value / Constants.thousand
        let millionNum = value / Constants.million

        return ""
    }
}

extension CommonMarketCapFormatter {
    struct Options {
        let minFractionDigits: Int
        let maxFractionDigits: Int
        let roundingType: AmountRoundingType?

        static var `default`: Options {
            .init(
                minFractionDigits: 3,
                maxFractionDigits: 3,
                roundingType: .default(roundingMode: .plain, scale: 3)
            )
        }
    }

    private enum Constants {
        static let thousand: Decimal = 1000
        static let million: Decimal = 1000000
    }
}
