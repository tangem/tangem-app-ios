//
//  TangemBadge+Style.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension TangemBadge {
    static func textColor(type: BadgeType, color: BadgeColor) -> Color {
        switch type {
        case .solid:
            return Color.Tangem.Text.Neutral.primaryInvertedConstant
        case .tinted, .outline:
            switch color {
            case .blue:
                return Color.Tangem.Markers.textBlue
            case .red:
                return Color.Tangem.Markers.textRed
            case .gray:
                return Color.Tangem.Markers.textGray
            }
        }
    }

    static func iconColor(type: BadgeType, color: BadgeColor) -> Color {
        switch type {
        case .solid:
            return Color.Tangem.Graphic.Neutral.primaryInvertedConstant
        case .tinted, .outline:
            switch color {
            case .blue:
                return Color.Tangem.Markers.iconBlue
            case .red:
                return Color.Tangem.Markers.iconRed
            case .gray:
                return Color.Tangem.Markers.iconGray
            }
        }
    }

    static func backgroundColor(type: BadgeType, color: BadgeColor) -> Color? {
        switch type {
        case .solid:
            switch color {
            case .blue:
                return Color.Tangem.Markers.backgroundSolidBlue
            case .red:
                return Color.Tangem.Markers.backgroundSolidRed
            case .gray:
                return Color.Tangem.Markers.backgroundSolidGray
            }
        case .tinted:
            switch color {
            case .blue:
                return Color.Tangem.Markers.backgroundTintedBlue
            case .red:
                return Color.Tangem.Markers.backgroundTintedRed
            case .gray:
                return Color.Tangem.Markers.backgroundTintedGray
            }
        case .outline:
            return nil
        }
    }

    static func borderColor(type: BadgeType, color: BadgeColor) -> Color? {
        switch type {
        case .solid, .tinted:
            return nil
        case .outline:
            switch color {
            case .blue:
                return Color.Tangem.Markers.borderTintedBlue
            case .red:
                return Color.Tangem.Markers.borderTintedRed
            case .gray:
                return Color.Tangem.Markers.borderGray
            }
        }
    }
}
