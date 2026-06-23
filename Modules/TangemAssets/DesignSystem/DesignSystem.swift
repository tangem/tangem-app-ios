//
//  DesignSystem.swift
//  TangemAssets
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// The `DesignSystem` namespace tree itself is generated from the DS-Core
// `codeSyntax.iOS` paths into `Generated/DesignSystem/Namespaces+Generated.swift`.
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
    public let relativeTo: Font.TextStyle
    public let lineHeight: CGFloat
    public let lineSpacing: CGFloat
    public let tracking: CGFloat

    public init(
        fontFamily: String,
        fontWeight: Font.Weight,
        fontSize: CGFloat,
        relativeTo: Font.TextStyle,
        lineHeight: CGFloat,
        lineSpacing: CGFloat,
        tracking: CGFloat
    ) {
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight
        self.fontSize = fontSize
        self.relativeTo = relativeTo
        self.lineHeight = lineHeight
        self.lineSpacing = lineSpacing
        self.tracking = tracking
    }

    public var font: Font {
        // `relativeTo:` opts the font into Dynamic Type scaling — the size grows
        // with the user's preferred content size relative to the given text style.
        // `.custom` is the only builder with a `relativeTo:` overload (`.system`
        // has none), so all tiers route through it. The "SF Pro" family is not a
        // registered PostScript name, so it silently resolves to the system SF
        // face — exactly what design wants on iOS — now with Dynamic Type.
        .custom(fontFamily, size: fontSize, relativeTo: relativeTo).weight(fontWeight)
    }
}

public extension View {
    func font(_ token: TangemTypographyToken) -> some View {
        font(token.font)
            .lineSpacing(token.lineSpacing)
            .tracking(token.tracking)
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
