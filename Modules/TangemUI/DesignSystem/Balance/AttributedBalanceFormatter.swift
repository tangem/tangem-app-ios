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
        let font: Font?
        let tracking: CGFloat
        /// `nil` leaves the part's color unset so it inherits the ambient `foregroundStyle`
        /// (e.g. an animated price-change flash).
        public let color: Color?

        public init(font: Font?, color: Color?) {
            self.font = font
            tracking = 0
            self.color = color
        }

        public init(token: TangemTypographyToken?, color: Color?) {
            font = token.map { Font.system(size: $0.fontSize, weight: $0.fontWeight) }
            tracking = token?.tracking ?? 0
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
            attributed.font = integerFont
            attributed.tracking = integerPart.tracking
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
            attributed[fractionalRange].font = fractionalFont
            attributed[fractionalRange].tracking = fractionalPart.tracking
        }
        if let fractionalColor = fractionalPart.color {
            attributed[fractionalRange].foregroundColor = fractionalColor
        }

        return attributed
    }

    /// Only plain-string balances are recolored; already-attributed or builder-based values pass through untouched.
    public static func splitFonts(
        _ state: LoadableBalanceView.State,
        decimalSeparator: String = Locale.current.decimalSeparator ?? ".",
        integerPart: PartStyle,
        fractionalPart: PartStyle,
        fractionalIncludesSeparator: Bool = true
    ) -> LoadableBalanceView.State {
        func split(_ text: LoadableBalanceView.Text) -> LoadableBalanceView.Text {
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
            return .loaded(text: split(text))
        case .loading(let cached):
            return .loading(cached: cached.map(split))
        case .failed(let cached, let icon):
            return .failed(cached: split(cached), icon: icon)
        }
    }

    // MARK: - Convenience

    public static func splitFonts(
        _ state: LoadableBalanceView.State,
        integerFont: TangemTypographyToken,
        fractionalFont: TangemTypographyToken,
        color: Color = DesignSystem.Color.textPrimary,
        fractionalIncludesSeparator: Bool = true
    ) -> LoadableBalanceView.State {
        splitFonts(
            state,
            integerPart: PartStyle(token: integerFont, color: color),
            fractionalPart: PartStyle(token: fractionalFont, color: color),
            fractionalIncludesSeparator: fractionalIncludesSeparator
        )
    }
}
