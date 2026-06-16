//
//  DesignSystem.swift
//  TangemAssets
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// The `DesignSystem` namespace tree itself is generated from the DS-Core
// `codeSyntax.iOS` paths into `Generated/DesignSystem/Skeleton+Generated.swift`.
// This file holds only the hand-written runtime: color helpers, token value
// types, and `View` modifiers consumed by the generated extensions.

// MARK: - Color helpers (used by generated code)

extension SwiftUI.Color {
    init(hex8: UInt32) {
        let a = Double((hex8 >> 24) & 0xFF) / 255.0
        let r = Double((hex8 >> 16) & 0xFF) / 255.0
        let g = Double((hex8 >> 8) & 0xFF) / 255.0
        let b = Double(hex8 & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    static func dsTokensDynamic(light: UIColor, dark: UIColor) -> SwiftUI.Color {
        SwiftUI.Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}

extension UIColor {
    convenience init(hex8: UInt32) {
        let a = CGFloat((hex8 >> 24) & 0xFF) / 255.0
        let r = CGFloat((hex8 >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex8 >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex8 & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - Typography token

public struct TangemTypographyToken: Hashable, Sendable {
    public let fontFamily: String
    public let fontWeight: Font.Weight
    public let fontSize: CGFloat
    public let lineHeight: CGFloat
    public let letterSpacing: CGFloat

    public init(
        fontFamily: String,
        fontWeight: Font.Weight,
        fontSize: CGFloat,
        lineHeight: CGFloat,
        letterSpacing: CGFloat
    ) {
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
    }

    public var font: Font {
        // Route SF Pro through `.system(...)` — the canonical primitive for the
        // platform font. `.custom("SF Pro", ...)` would not resolve (PostScript
        // names are "SFPro-Regular" etc.) and would silently fall back to system,
        // hiding misconfiguration. Non-system families go through `.custom`,
        // which assumes registration via Info.plist (UIAppFonts).
        if fontFamily == "SF Pro" {
            return .system(size: fontSize, weight: fontWeight)
        }
        return .custom(fontFamily, size: fontSize).weight(fontWeight)
    }
}

public extension View {
    func font(_ token: TangemTypographyToken) -> some View {
        modifier(TangemTypographyTokenModifier(token: token))
    }
}

private struct TangemTypographyTokenModifier: ViewModifier {
    let token: TangemTypographyToken
    @ScaledMetric private var scaledSize: CGFloat

    init(token: TangemTypographyToken) {
        self.token = token
        _scaledSize = ScaledMetric(wrappedValue: token.fontSize, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        content
            .font(scaledFont)
            .lineSpacing(max(0, scaledLineHeight - scaledSize))
            .tracking(token.letterSpacing)
    }

    private var scaledFont: Font {
        if token.fontFamily == "SF Pro" {
            return .system(size: scaledSize, weight: token.fontWeight)
        }
        return .custom(token.fontFamily, size: scaledSize).weight(token.fontWeight)
    }

    private var scaledLineHeight: CGFloat {
        guard token.fontSize > 0 else { return token.lineHeight }

        return token.lineHeight * (scaledSize / token.fontSize)
    }
}

// MARK: - Shadow token

public struct TangemShadowToken: Hashable, Sendable {
    public let blur: CGFloat
    public let offsetX: CGFloat
    public let offsetY: CGFloat
    /// CSS-style shadow expansion. Preserved on the iOS struct for parity with the
    /// DS-Core JSON schema (Figma origin), but currently **ignored by `tangemShadow`** —
    /// SwiftUI's `.shadow` has no spread primitive. Today every shipped DS-Core
    /// shadow has `spread: 0`, so the gap is invisible in practice.
    public let spread: CGFloat
    public let color: SwiftUI.Color

    public init(
        blur: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        spread: CGFloat,
        color: SwiftUI.Color
    ) {
        self.blur = blur
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.spread = spread
        self.color = color
    }
}

public extension View {
    func tangemShadow(_ token: TangemShadowToken) -> some View {
        shadow(color: token.color, radius: token.blur, x: token.offsetX, y: token.offsetY)
    }
}
