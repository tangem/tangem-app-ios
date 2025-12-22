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

    private var repository: PercentFormatterNumberFormatterRepository { .shared }

    init(locale: Locale = .current) {
        self.locale = locale
    }

    /// - Warning: The internal implementation of this method is using cache;
    /// therefore don't forget to update the repository if a new parameter is added to this method.
    func format(_ value: Decimal, option: Option) -> String {
        let formatter: NumberFormatter

        if let cachedFormatter = repository.numberFormatter(locale: locale, option: option, uniqueIdentifier: #function) {
            formatter = cachedFormatter
        } else {
            formatter = makeFormatter(option: option)
            repository.storeNumberFormatter(formatter, locale: locale, option: option, uniqueIdentifier: #function)
        }

        if let formatted = formatter.string(from: value as NSDecimalNumber) {
            return formatted
        }

        return "\(value)%"
    }

    /// - Warning: The internal implementation of this method is using cache;
    /// therefore don't forget to update the repository if a new parameter is added to this method.
    func formatInterval(min: Decimal, max: Decimal) -> String {
        let option = Option.interval
        let formatter: NumberFormatter

        if let cachedFormatter = repository.numberFormatter(locale: locale, option: option, uniqueIdentifier: #function) {
            formatter = cachedFormatter
        } else {
            formatter = makeFormatter(option: option)
            repository.storeNumberFormatter(formatter, locale: locale, option: option, uniqueIdentifier: #function)
        }

        let minFormatted = formatter.string(from: min as NSDecimalNumber) ?? "\(min)"
        let maxFormatted = format(max, option: option)

        return "\(minFormatted) - \(maxFormatted)"
    }

    // MARK: - Factory methods

    /// Makes a formatter instance to be used in `format(_:option:)`.
    func makeFormatter(option: Option) -> NumberFormatter {
        let formatter = NumberFormatter()

        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.maximumFractionDigits = option.fractionDigits.max
        formatter.minimumFractionDigits = option.fractionDigits.min

        formatter.negativePrefix = option.prefix.negative
        formatter.positivePrefix = option.prefix.positive

        formatter.positiveSuffix = option.suffix.value
        formatter.negativeSuffix = option.suffix.value

        return formatter
    }
}

// MARK: Default options

extension PercentFormatter.Option {
    static let slippage = PercentFormatter.Option(fractionDigits: .init(min: 0, max: 1), prefix: .empty, suffix: .default)
    static let priceChange = PercentFormatter.Option(fractionDigits: .two, prefix: .empty, suffix: .default)

    static let staking = PercentFormatter.Option(fractionDigits: .two, prefix: .empty, suffix: .default)
    static let interval = PercentFormatter.Option(fractionDigits: .two, prefix: .empty, suffix: .empty)

    static let express = PercentFormatter.Option(fractionDigits: .one, prefix: .default, suffix: .default)
    static let onramp = PercentFormatter.Option(fractionDigits: .two, prefix: .onlyMinus, suffix: .default)

    static let yield = PercentFormatter.Option(fractionDigits: .two, prefix: .empty, suffix: .yield)
    static let yieldEmptySuffix = PercentFormatter.Option(fractionDigits: .one, prefix: .empty, suffix: .empty)
}

// MARK: Options

extension PercentFormatter {
    struct Option: Hashable {
        let fractionDigits: FractionDigits
        let prefix: Prefix
        let suffix: Suffix
    }

    struct FractionDigits: Hashable {
        static let one = FractionDigits(min: 1, max: 1)
        static let two = FractionDigits(min: 2, max: 2)

        let min: Int
        let max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }
    }

    struct Prefix: Hashable {
        static let empty = Prefix(positive: "", negative: "")
        static let `default` = Prefix(positive: "+", negative: "-")
        static let onlyMinus = Prefix(positive: "", negative: "-")

        let positive: String
        let negative: String
    }

    struct Suffix: Hashable {
        static let empty = Suffix(value: "")
        static let `default` = Suffix(value: " %")
        static let yield = Suffix(value: "%")

        let value: String
    }
}
