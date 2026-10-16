//
//  TangemBadge+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public extension TangemBadge {
    enum Size: Equatable, Sendable {
        case x4
        case x6
        case x9

        var baseHeight: CGFloat {
            switch self {
            case .x4: 16
            case .x6: 24
            case .x9: 36
            }
        }

        var baseIconSize: CGFloat {
            switch self {
            case .x4: 12
            case .x6: 16
            case .x9: 16
            }
        }

        var baseHorizontalPadding: CGFloat {
            switch self {
            case .x4: 4
            case .x6: 8
            case .x9: 12
            }
        }

        var baseContentSpacing: CGFloat {
            switch self {
            case .x4: 2
            case .x6: 4
            case .x9: 4
            }
        }

        var font: TangemFontStyle {
            switch self {
            case .x4: Font.Tangem.Caption11.semibold
            case .x6: Font.Tangem.Caption12.semibold
            case .x9: Font.Tangem.Caption13.semibold
            }
        }
    }

    enum Shape: Equatable, Sendable {
        case rectangular
        case rounded

        func cornerRadius(for size: Size) -> CGFloat {
            switch size {
            case .x4: 4
            case .x6: 8
            case .x9: 8
            }
        }
    }

    enum BadgeColor: Equatable, Sendable {
        case blue
        case red
        case yellow
        case gray
    }

    enum BadgeType: Equatable, Sendable {
        case solid
        case tinted
        case outline
    }

    enum IconPosition: Equatable, Sendable {
        case leading
        case trailing
    }
}
