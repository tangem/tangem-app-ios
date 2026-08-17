//
//  MarketsTokenPriceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemFoundation

/// An experimental implementation, currently used only in the `Markets` module.
/// Most likely requires some tuning and improvements ([REDACTED_INFO] and [REDACTED_INFO]).
final class MarketsTokenPriceFormatter {
    /// - threshold: Values like `0.1`, `0.01`, `0.001` and so on; used for the quick lookup of a cached scale value.
    /// - scale: Scale of a decimal number
    private typealias Scale = (threshold: Decimal, scale: Int)

    /// Scale computation is resource-heavy, so the results are cached. The cache is shared by formatter
    /// instances living in view models that format on different queues, hence the lock.
    private static let cachedScales: OSAllocatedUnfairLock<[Scale]> = {
        var cachedScales: [Scale] = []
        cachedScales.reserveCapacity(128) // Maximum scale of `Decimal`
        return OSAllocatedUnfairLock(initialState: cachedScales)
    }()

    private let fractionalPartLengthAfterLeadingZeroes: Int
    private let balanceFormatter = BalanceFormatter()
    private var defaultFormattingOptions: BalanceFormattingOptions { .defaultFiatFormattingOptions }

    init(fractionalPartLengthAfterLeadingZeroes: Int = Constants.fractionalPartLengthAfterLeadingZeroes) {
        self.fractionalPartLengthAfterLeadingZeroes = fractionalPartLengthAfterLeadingZeroes
    }

    func formatPrice(_ value: Decimal?) -> String {
        // Values outside the `(0, 1)` range and absent values are formatted using default formatting options;
        // non-positive values must not reach the scale calculation: its ladder either never terminates
        // (iOS 16/17 Foundation) or poisons the cache with NaN thresholds (iOS 18+)
        guard
            let value,
            value > 0,
            value < 1.0
        else {
            return formatPrice(value, formattingOptions: defaultFormattingOptions)
        }

        let scale = Self.cachedScales.withLock { cachedScales in
            Self.scale(
                for: value,
                fractionalPartLengthAfterLeadingZeroes: fractionalPartLengthAfterLeadingZeroes,
                cachedScales: &cachedScales
            )
        }

        return formatPrice(value, formattingOptions: makeFormattingOptions(forScale: scale))
    }

    func formatPrice(_ price: String) -> AttributedString {
        let formattingOptions = TotalBalanceFormattingOptions(
            integerPartFont: Font.Tangem.Title44.semibold,
            fractionalPartFont: Font.Tangem.Title44.semibold,
            integerPartColor: .Tangem.Text.Neutral.primary,
            fractionalPartColor: .Tangem.Text.Neutral.secondary,
            fractionalPartIncludesDecimalSeparator: true
        )

        return balanceFormatter.formatAttributedTotalBalance(
            fiatBalance: price,
            formattingOptions: formattingOptions
        )
    }

    private static func scale(
        for value: Decimal,
        fractionalPartLengthAfterLeadingZeroes: Int,
        cachedScales: inout [Scale]
    ) -> Int {
        // Check if the scale for a given `value` has been calculated previously and stored in the cache
        for (threshold, scale) in cachedScales {
            if value >= threshold {
                return scale
            }
        }

        // We got a cache miss; calculating the scale and threshold for a given `value`
        // Scales are calculated from the last known scale (from `cachedScales`) up to (and including) the scale of the current `value`
        var fractionalPartLeadingZeroesCount: Int
        var threshold: Decimal

        if let lastCachedScale = cachedScales.last {
            fractionalPartLeadingZeroesCount = lastCachedScale.scale - fractionalPartLengthAfterLeadingZeroes + 1
            threshold = lastCachedScale.threshold
        } else {
            fractionalPartLeadingZeroesCount = 0
            threshold = 1 // `ExpressibleByIntegerLiteral` maintains required precision, unlike `ExpressibleByFloatLiteral`
        }

        let step: Decimal = 10 // `ExpressibleByIntegerLiteral` maintains required precision, unlike `ExpressibleByFloatLiteral`

        while threshold > value {
            threshold /= step

            let scale = fractionalPartLeadingZeroesCount + fractionalPartLengthAfterLeadingZeroes
            cachedScales.append((threshold, scale))

            fractionalPartLeadingZeroesCount += 1
        }

        return cachedScales.last?.scale ?? 0
    }

    private func makeFormattingOptions(forScale scale: Int) -> BalanceFormattingOptions {
        var formattingOptions: BalanceFormattingOptions = .defaultFiatFormattingOptions
        formattingOptions.maxFractionDigits = scale
        formattingOptions.roundingType = .default(roundingMode: .plain, scale: scale)

        return formattingOptions
    }

    private func formatPrice(_ value: Decimal?, formattingOptions: BalanceFormattingOptions) -> String {
        let currencyCode = AppSettings.shared.selectedCurrencyCode

        return balanceFormatter.formatFiatBalance(
            value,
            currencyCode: currencyCode,
            formattingOptions: formattingOptions
        )
    }
}

// MARK: - Constants

private extension MarketsTokenPriceFormatter {
    enum Constants {
        /// This default value of `fractionalPartLengthAfterLeadingZeroes` apparently corresponds to the one used by CMC.
        static let fractionalPartLengthAfterLeadingZeroes = 4
    }
}
