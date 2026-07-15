//
//  GlowRingAppearance.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

/// Glow ring color appearance. `magic` morphs between two palettes (ping-pong); the rest are static.
public enum GlowRingAppearance: Sendable, Hashable, CaseIterable {
    case magic
    case success
    case error
    case warning
    case info
}

extension GlowRingAppearance {
    var palette: GlowRingModifier.Palette {
        switch self {
        case .magic:
            GlowRingModifier.Palette(stopsA: Self.stops(Self.magicColors), stopsB: Self.stops(Self.magicBlendColors))
        case .success:
            GlowRingModifier.Palette(stopsA: Self.stops(Self.successColors))
        case .error:
            GlowRingModifier.Palette(stopsA: Self.stops(Self.errorColors))
        case .warning:
            GlowRingModifier.Palette(stopsA: Self.stops(Self.warningColors))
        case .info:
            GlowRingModifier.Palette(stopsA: Self.stops(Self.infoColors))
        }
    }
}

private extension GlowRingAppearance {
    /// Figma "Glow Ring Gradient" stop positions. The 10 palette colors map to the first ten;
    /// color 1 repeats at 1.0 to close the loop at the seam.
    static let stopLocations: [CGFloat] = [0.00, 0.10, 0.25, 0.30, 0.40, 0.50, 0.60, 0.70, 0.85, 0.95, 1.00]

    static func stops(_ colors: [Color]) -> [Gradient.Stop] {
        guard let first = colors.first else { return [] }
        return zip(colors + [first], stopLocations).map { Gradient.Stop(color: $0, location: $1) }
    }

    static let magicColors: [Color] = [
        DesignSystem.Color.glowMagicStep1, DesignSystem.Color.glowMagicStep2, DesignSystem.Color.glowMagicStep3,
        DesignSystem.Color.glowMagicStep4, DesignSystem.Color.glowMagicStep5, DesignSystem.Color.glowMagicStep6,
        DesignSystem.Color.glowMagicStep7, DesignSystem.Color.glowMagicStep8, DesignSystem.Color.glowMagicStep9,
        DesignSystem.Color.glowMagicStep10,
    ]

    static let magicBlendColors: [Color] = [
        DesignSystem.Color.glowMagicBlendStep1, DesignSystem.Color.glowMagicBlendStep2, DesignSystem.Color.glowMagicBlendStep3,
        DesignSystem.Color.glowMagicBlendStep4, DesignSystem.Color.glowMagicBlendStep5, DesignSystem.Color.glowMagicBlendStep6,
        DesignSystem.Color.glowMagicBlendStep7, DesignSystem.Color.glowMagicBlendStep8, DesignSystem.Color.glowMagicBlendStep9,
        DesignSystem.Color.glowMagicBlendStep10,
    ]

    static let successColors: [Color] = [
        DesignSystem.Color.glowSuccessStep1, DesignSystem.Color.glowSuccessStep2, DesignSystem.Color.glowSuccessStep3,
        DesignSystem.Color.glowSuccessStep4, DesignSystem.Color.glowSuccessStep5, DesignSystem.Color.glowSuccessStep6,
        DesignSystem.Color.glowSuccessStep7, DesignSystem.Color.glowSuccessStep8, DesignSystem.Color.glowSuccessStep9,
        DesignSystem.Color.glowSuccessStep10,
    ]

    static let errorColors: [Color] = [
        DesignSystem.Color.glowErrorStep1, DesignSystem.Color.glowErrorStep2, DesignSystem.Color.glowErrorStep3,
        DesignSystem.Color.glowErrorStep4, DesignSystem.Color.glowErrorStep5, DesignSystem.Color.glowErrorStep6,
        DesignSystem.Color.glowErrorStep7, DesignSystem.Color.glowErrorStep8, DesignSystem.Color.glowErrorStep9,
        DesignSystem.Color.glowErrorStep10,
    ]

    static let warningColors: [Color] = [
        DesignSystem.Color.glowWarningStep1, DesignSystem.Color.glowWarningStep2, DesignSystem.Color.glowWarningStep3,
        DesignSystem.Color.glowWarningStep4, DesignSystem.Color.glowWarningStep5, DesignSystem.Color.glowWarningStep6,
        DesignSystem.Color.glowWarningStep7, DesignSystem.Color.glowWarningStep8, DesignSystem.Color.glowWarningStep9,
        DesignSystem.Color.glowWarningStep10,
    ]

    static let infoColors: [Color] = [
        DesignSystem.Color.glowInfoStep1, DesignSystem.Color.glowInfoStep2, DesignSystem.Color.glowInfoStep3,
        DesignSystem.Color.glowInfoStep4, DesignSystem.Color.glowInfoStep5, DesignSystem.Color.glowInfoStep6,
        DesignSystem.Color.glowInfoStep7, DesignSystem.Color.glowInfoStep8, DesignSystem.Color.glowInfoStep9,
        DesignSystem.Color.glowInfoStep10,
    ]
}
