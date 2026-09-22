//
//  FeedProductCardView+Appearance.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension FeedProductCardView {
    enum Appearance {
        case pay
        case earn
        case referral
        case polymarket

        var icon: Image {
            switch self {
            case .pay: Assets.Visa.logo.image
            case .earn: DesignSystem.Icons.ChartLineVertical.regular20.image
            // [REDACTED_TODO_COMMENT]
            case .referral: Assets.Accounts.gift.image
            case .polymarket: DesignSystem.Icons.MagicBall.regular20.image
            }
        }

        var iconSize: CGSize {
            switch self {
            case .pay: CGSize(width: 22, height: 8)
            case .earn, .referral, .polymarket: CGSize(width: 20, height: 20)
            }
        }

        var iconOpacity: Double {
            self == .pay ? 0.9 : 1
        }

        // [REDACTED_TODO_COMMENT]
        var color: Color {
            switch self {
            case .pay: Color(red: 82 / 255, green: 50 / 255, blue: 243 / 255)
            case .earn: DesignSystem.Color.bgAccentBlue
            case .referral: Color(red: 195 / 255, green: 83 / 255, blue: 121 / 255)
            case .polymarket: Color(red: 169 / 255, green: 103 / 255, blue: 253 / 255)
            }
        }

        var showsHighlight: Bool {
            self != .pay
        }
    }
}
