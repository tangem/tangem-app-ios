//
//  Font+.swift
//  TangemAssets
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - TangemFontStyle

public struct TangemFontStyle: Hashable, Sendable {
    public let font: Font
    public let tracking: CGFloat
    let metrics: Metrics?

    struct Metrics: Hashable, Sendable {
        let size: CGFloat
        let lineHeight: CGFloat
        let weight: Font.Weight
    }

    /// Redesign tier: fixed `sp` size + line height, applied with `@ScaledMetric` on the `View` path.
    init(size: CGFloat, lineHeight: CGFloat, weight: Font.Weight, tracking: CGFloat) {
        font = .system(size: size, weight: weight)
        self.tracking = tracking
        metrics = Metrics(size: size, lineHeight: lineHeight, weight: weight)
    }

    /// Legacy wrap: a raw `Font` with no line height (used by `[REDACTED_INFO]` redesign toggles).
    public init(font: Font, tracking: CGFloat = 0) {
        self.font = font
        self.tracking = tracking
        metrics = nil
    }

    public init(_ token: TangemTypographyToken) {
        self.init(font: token.font, tracking: token.tracking)
    }
}

public extension View {
    func font(_ style: TangemFontStyle) -> some View {
        modifier(TangemFontStyleModifier(style: style))
    }

    func style(_ style: TangemFontStyle, color: Color) -> some View {
        modifier(TangemFontStyleModifier(style: style)).foregroundStyle(color)
    }
}

private struct TangemFontStyleModifier: ViewModifier {
    let style: TangemFontStyle
    @ScaledMetric private var scaledSize: CGFloat

    init(style: TangemFontStyle) {
        self.style = style
        _scaledSize = ScaledMetric(wrappedValue: style.metrics?.size ?? 0, relativeTo: .body)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if let metrics = style.metrics {
            content
                .font(.system(size: scaledSize, weight: metrics.weight))
                .lineSpacing(scaledLineSpacing(metrics))
                .tracking(style.tracking)
        } else {
            content
                .font(style.font)
                .tracking(style.tracking)
        }
    }

    /// `lineSpacing` adds to the font's intrinsic line height, so the gap is the design line height
    /// minus the font's natural line height — not minus the point size.
    private func scaledLineSpacing(_ metrics: TangemFontStyle.Metrics) -> CGFloat {
        max(0, scaledLineHeight(metrics) - intrinsicLineHeight(metrics))
    }

    private func scaledLineHeight(_ metrics: TangemFontStyle.Metrics) -> CGFloat {
        guard metrics.size > 0 else { return metrics.lineHeight }

        return metrics.lineHeight * (scaledSize / metrics.size)
    }

    private func intrinsicLineHeight(_ metrics: TangemFontStyle.Metrics) -> CGFloat {
        UIFont.systemFont(ofSize: scaledSize, weight: metrics.weight.uiWeight).lineHeight
    }
}

private extension Font.Weight {
    var uiWeight: UIFont.Weight {
        switch self {
        case .ultraLight: .ultraLight
        case .thin: .thin
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        default: .regular
        }
    }
}

public extension AttributedString {
    mutating func setFontStyle(_ style: TangemFontStyle) {
        var container = AttributeContainer()
        container.font = style.font
        container.tracking = style.tracking
        mergeAttributes(container)
    }
}

// MARK: - Tangem fonts ([REDACTED_INFO]: weights collapsed; each tier carries design tracking)

public extension Font {
    enum Tangem {
        public enum Caption11 {}
        public enum Caption12 {}
        public enum Caption13 {}
        public enum Subheadline {}
        public enum Body14 {}
        public enum Body15 {}
        public enum Body16 {}
        public enum Heading17 {}
        public enum Heading20 {}
        public enum Heading22 {}
        public enum Heading28 {}
        public enum Heading34 {}
        public enum Title44 {}
    }
}

// MARK: - Caption11

public extension Font.Tangem.Caption11 {
    static let medium = TangemFontStyle(size: 11, lineHeight: 12, weight: .medium, tracking: 0.06)
    static let regular = medium
    static let semibold = TangemFontStyle(size: 11, lineHeight: 12, weight: .medium, tracking: 0.15)
}

// MARK: - Caption12

public extension Font.Tangem.Caption12 {
    static let medium = TangemFontStyle(size: 12, lineHeight: 16, weight: .medium, tracking: 0)
    static let regular = medium
    static let semibold = TangemFontStyle(size: 12, lineHeight: 16, weight: .medium, tracking: 0.1)
}

// MARK: - Caption13

public extension Font.Tangem.Caption13 {
    static let medium = TangemFontStyle(size: 13, lineHeight: 16, weight: .medium, tracking: -0.08)
    static let regular = medium
    static let semibold = TangemFontStyle(size: 13, lineHeight: 16, weight: .medium, tracking: 0.1)
}

// MARK: - Subheadline

public extension Font.Tangem.Subheadline {
    static let medium = TangemFontStyle(size: 14, lineHeight: 16, weight: .medium, tracking: -0.15)
    static let regular = medium
}

// MARK: - Body14

public extension Font.Tangem.Body14 {
    static let regular = TangemFontStyle(size: 14, lineHeight: 16, weight: .medium, tracking: -0.15)
}

// MARK: - Body15

public extension Font.Tangem.Body15 {
    static let medium = TangemFontStyle(size: 15, lineHeight: 16, weight: .medium, tracking: -0.23)
    static let regular = medium
    static let semibold = medium
}

// MARK: - Body16

public extension Font.Tangem.Body16 {
    static let medium = TangemFontStyle(size: 16, lineHeight: 20, weight: .medium, tracking: -0.31)
    static let regular = medium
    static let semibold = medium
}

// MARK: - Heading17

public extension Font.Tangem.Heading17 {
    static let semibold = TangemFontStyle(size: 17, lineHeight: 20, weight: .semibold, tracking: -0.12)
}

// MARK: - Heading20

public extension Font.Tangem.Heading20 {
    static let semibold = TangemFontStyle(size: 20, lineHeight: 24, weight: .semibold, tracking: -0.12)
}

// MARK: - Heading22

public extension Font.Tangem.Heading22 {
    static let semibold = TangemFontStyle(size: 22, lineHeight: 28, weight: .semibold, tracking: -0.12)
}

// MARK: - Heading28

public extension Font.Tangem.Heading28 {
    static let semibold = TangemFontStyle(size: 28, lineHeight: 36, weight: .semibold, tracking: -0.37)
}

// MARK: - Heading34

public extension Font.Tangem.Heading34 {
    static let semibold = TangemFontStyle(size: 34, lineHeight: 44, weight: .semibold, tracking: -0.37)
}

// MARK: - Title44

public extension Font.Tangem.Title44 {
    static let semibold = TangemFontStyle(size: 44, lineHeight: 48, weight: .semibold, tracking: -0.92)
}
