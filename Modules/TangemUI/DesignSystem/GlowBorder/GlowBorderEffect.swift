//
//  GlowBorderEffect.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Gradient colors would never be design system part, so can be added like this -> this needs for more flexibility
public enum GlowBorderEffect: Equatable, Sendable {
    case none
    case bannerCard
    case bannerMagic
    case bannerWarning

    var glowColors: [Color] {
        switch self {
        case .none:
            return []
        case .bannerCard:
            return [
                Color(red: 19 / 255, green: 25 / 255, blue: 243 / 255),
                Color(red: 255 / 255, green: 0 / 255, blue: 93 / 255),
                Color(red: 255 / 255, green: 0 / 255, blue: 93 / 255),
                Color(red: 234 / 255, green: 178 / 255, blue: 22 / 255),
                Color(red: 234 / 255, green: 178 / 255, blue: 22 / 255),
                Color(red: 210 / 255, green: 31 / 255, blue: 242 / 255),
                Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255),
            ]
        case .bannerMagic:
            return [
                Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255),
                Color(red: 74 / 255, green: 64 / 255, blue: 211 / 255),
                Color(red: 204 / 255, green: 77 / 255, blue: 140 / 255),
                Color(red: 224 / 255, green: 188 / 255, blue: 86 / 255),
                Color(red: 118 / 255, green: 228 / 255, blue: 99 / 255),
                Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255),
            ]
        case .bannerWarning:
            return [
                Color(red: 255 / 255, green: 172 / 255, blue: 193 / 255),
                Color(red: 255 / 255, green: 0 / 255, blue: 4 / 255),
                Color(red: 255 / 255, green: 0 / 255, blue: 4 / 255),
                Color(red: 224 / 255, green: 188 / 255, blue: 86 / 255),
                Color(red: 255 / 255, green: 0 / 255, blue: 0 / 255),
                Color(red: 255 / 255, green: 172 / 255, blue: 193 / 255),
            ]
        }
    }

    var backgroundColor: Color {
        switch self {
        case .none, .bannerCard, .bannerMagic:
            Color.Tangem.Fill.Neutral.bannerBackground
        case .bannerWarning:
            Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(Color(red: 20 / 255, green: 0 / 255, blue: 0 / 255))
                    : UIColor(Color.Tangem.Fill.Neutral.bannerBackground)
            })
        }
    }

    var strokeGradientColors: [Color] {
        switch self {
        case .none, .bannerCard, .bannerMagic:
            return [
                Color.Tangem.Border.Neutral.banner.opacity(0.3),
                Color.Tangem.Border.Neutral.banner,
                Color.Tangem.Border.Neutral.banner.opacity(0.3),
                Color.Tangem.Border.Neutral.banner,
            ]
        case .bannerWarning:
            return [
                Color(red: 228 / 255, green: 72 / 255, blue: 72 / 255).opacity(0.3),
                Color(red: 228 / 255, green: 72 / 255, blue: 72 / 255),
                Color(red: 228 / 255, green: 72 / 255, blue: 72 / 255).opacity(0.3),
                Color(red: 228 / 255, green: 72 / 255, blue: 72 / 255),
            ]
        }
    }
}
