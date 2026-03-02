//
//  TangemBadge+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public extension TangemBadge {
    enum Size: Equatable, Sendable {
        case x4
        case x6
        case x9

        var baseHeight: CGFloat {
            switch self {
            case .x4: SizeUnit.x4.value
            case .x6: SizeUnit.x6.value
            case .x9: SizeUnit.x9.value
            }
        }

        var baseIconSize: CGFloat {
            switch self {
            case .x4: SizeUnit.x3.value
            case .x6: SizeUnit.x4.value
            case .x9: SizeUnit.x4.value
            }
        }

        var baseHorizontalPadding: CGFloat {
            switch self {
            case .x4: SizeUnit.x1.value
            case .x6: SizeUnit.x2.value
            case .x9: SizeUnit.x3.value
            }
        }

        var baseContentSpacing: CGFloat {
            switch self {
            case .x4: SizeUnit.half.value
            case .x6: SizeUnit.x1.value
            case .x9: SizeUnit.x1.value
            }
        }

        var font: Font {
            switch self {
            case .x4: .Tangem.caption2Semibold
            case .x6: .Tangem.caption1Medium
            case .x9: .Tangem.footnoteSemibold
            }
        }
    }

    enum Shape: Equatable, Sendable {
        case rectangular
        case rounded

        func cornerRadius(for size: Size) -> CGFloat {
            switch size {
            case .x4: SizeUnit.x1.value
            case .x6: SizeUnit.x2.value
            case .x9: SizeUnit.x2.value
            }
        }
    }

    enum BadgeColor: Equatable, Sendable {
        case blue
        case red
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
