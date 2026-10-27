//
//  ChangeSignType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

enum ChangeSignType: Int, Hashable {
    case positive
    case neutral
    case negative

    init(from value: Decimal) {
        if value == .zero {
            self = .neutral
        } else if value > 0 {
            self = .positive
        } else {
            self = .negative
        }
    }

    var textColor: Color {
        switch self {
        case .positive:
            return DesignSystem.Color.textAccentBlue
        case .neutral:
            return DesignSystem.Color.textSecondary
        case .negative:
            return DesignSystem.Color.textAccentRed
        }
    }

    /// Converts to the shared `PriceChangeView.ChangeType`.
    var priceChangeViewChangeType: PriceChangeView.ChangeType {
        switch self {
        case .positive:
            return .positive
        case .neutral:
            return .neutral
        case .negative:
            return .negative
        }
    }
}
