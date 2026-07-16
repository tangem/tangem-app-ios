//
//  AttributedBalanceFormatter.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation

/// Single source for split-color balances — route new dimmed-decimal balances here instead of re-rolling a formatter.
public enum AttributedBalanceFormatter {
    public struct PartStyle {
        /// Supply a font **only** when the integer and fractional parts must render in *different*
        /// fonts (a size split, e.g. a large integer with small decimals). For a uniform font leave
        /// this `nil` and apply the font on the view via `.style(_:)`/`.font(_:)`, so Dynamic Type
        /// scaling via `@ScaledMetric` is preserved — a baked fixed-size font would defeat it.
        public let font: TangemFontStyle?
        /// `nil` leaves the part's color unset so it inherits the ambient `foregroundStyle`
        /// (e.g. an animated price-change flash).
        public let color: Color?

        public init(font: TangemFontStyle?, color: Color?) {
            self.font = font
            self.color = color
        }
    }

    public static func format(
        _ balance: String,
        decimalSeparator: String,
        integerPart: PartStyle,
        fractionalPart: PartStyle,
        fractionalIncludesSeparator: Bool
    ) -> AttributedString {
        var attributed = AttributedString(balance)
        if let integerFont = integerPart.font {
            attributed.setFontStyle(integerFont)
        }

        guard
            decimalSeparator.isNotEmpty,
            let separatorRange = attributed.range(of: decimalSeparator)
        else {
            if let integerColor = integerPart.color {
                attributed.foregroundColor = integerColor
            }
            return attributed
        }

        let lowerBound = fractionalIncludesSeparator ? separatorRange.lowerBound : separatorRange.upperBound
        let integerRange = attributed.startIndex ..< lowerBound
        let fractionalRange = lowerBound ..< attributed.endIndex

        if let integerColor = integerPart.color {
            attributed[integerRange].foregroundColor = integerColor
        }

        if let fractionalFont = fractionalPart.font {
            attributed[fractionalRange].font = fractionalFont.font
            attributed[fractionalRange].tracking = fractionalFont.tracking
        }
        if let fractionalColor = fractionalPart.color {
            attributed[fractionalRange].foregroundColor = fractionalColor
        }

        return attributed
    }

    /// Only plain-string balances are recolored; already-attributed or builder-based values pass through untouched.
    public static func decimalColored(
        _ state: LoadableBalanceView.State,
        decimalSeparator: String = Locale.current.decimalSeparator ?? ".",
        integerPart: PartStyle,
        fractionalPart: PartStyle,
        fractionalIncludesSeparator: Bool = true
    ) -> LoadableBalanceView.State {
        func recolor(_ text: LoadableBalanceView.Text) -> LoadableBalanceView.Text {
            switch text {
            case .string(let raw):
                return .attributed(format(
                    raw,
                    decimalSeparator: decimalSeparator,
                    integerPart: integerPart,
                    fractionalPart: fractionalPart,
                    fractionalIncludesSeparator: fractionalIncludesSeparator
                ))
            case .attributed, .builder:
                return text
            }
        }

        switch state {
        case .loaded(let text):
            return .loaded(text: recolor(text))
        case .loading(let cached):
            return .loading(cached: cached.map(recolor))
        case .failed(let cached, let icon):
            return .failed(cached: recolor(cached), icon: icon)
        }
    }

    // MARK: - Convenience (canonical colors: integer Text.Neutral.primary, fractional Text.Neutral.secondary; pass nil to inherit)

    public static func format(
        _ balance: String,
        font: TangemFontStyle,
        integerColor: Color? = Color.Tangem.Text.Neutral.primary,
        fractionalColor: Color? = Color.Tangem.Text.Neutral.secondary,
        decimalSeparator: String = Locale.current.decimalSeparator ?? ".",
        fractionalIncludesSeparator: Bool = true
    ) -> AttributedString {
        format(
            balance,
            decimalSeparator: decimalSeparator,
            integerPart: PartStyle(font: font, color: integerColor),
            fractionalPart: PartStyle(font: font, color: fractionalColor),
            fractionalIncludesSeparator: fractionalIncludesSeparator
        )
    }

    /// Dims only the decimal tail via color and leaves both parts' font unset, so the caller applies
    /// a Dynamic Type-aware font through the SwiftUI `.font(_:)`/`.style(_:)` view modifier. The
    /// integer part is left uncolored so it follows the ambient `foregroundStyle` — e.g. a
    /// caller-driven price-change flash animation.
    public static func dimmingDecimals(
        _ balance: String,
        decimalColor: Color = Color.Tangem.Text.Neutral.secondary,
        decimalSeparator: String = Locale.current.decimalSeparator ?? ".",
        fractionalIncludesSeparator: Bool = true
    ) -> AttributedString {
        format(
            balance,
            decimalSeparator: decimalSeparator,
            integerPart: PartStyle(font: nil, color: nil),
            fractionalPart: PartStyle(font: nil, color: decimalColor),
            fractionalIncludesSeparator: fractionalIncludesSeparator
        )
    }

    public static func decimalColored(
        _ state: LoadableBalanceView.State,
        integerFont: TangemFontStyle,
        fractionalFont: TangemFontStyle,
        integerColor: Color? = Color.Tangem.Text.Neutral.primary,
        fractionalColor: Color? = Color.Tangem.Text.Neutral.secondary,
        fractionalIncludesSeparator: Bool = true
    ) -> LoadableBalanceView.State {
        decimalColored(
            state,
            integerPart: PartStyle(font: integerFont, color: integerColor),
            fractionalPart: PartStyle(font: fractionalFont, color: fractionalColor),
            fractionalIncludesSeparator: fractionalIncludesSeparator
        )
    }

    public static func decimalColored(
        _ state: LoadableBalanceView.State,
        font: TangemFontStyle,
        integerColor: Color? = Color.Tangem.Text.Neutral.primary,
        fractionalColor: Color? = Color.Tangem.Text.Neutral.secondary
    ) -> LoadableBalanceView.State {
        decimalColored(state, integerFont: font, fractionalFont: font, integerColor: integerColor, fractionalColor: fractionalColor)
    }
}
