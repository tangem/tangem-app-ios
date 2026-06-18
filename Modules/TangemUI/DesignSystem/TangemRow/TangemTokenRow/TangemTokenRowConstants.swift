//
//  TangemTokenRowConstants.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

/// Token-specific constants not covered by TangemRowConstants.
enum TangemTokenRowConstants {
    enum Style {
        enum TokenName {
            static let disabledColor: Color = .Tangem.Text.Neutral.tertiary
        }

        enum FiatBalance {
            static let font = Font.Tangem.Body15.semibold
            static let integerColor: Color = .Tangem.Text.Neutral.primary
            static let decimalColor: Color = .Tangem.Text.Neutral.secondary
        }

        enum TokenPrice {
            static let font = Font.Tangem.Caption12.regular
            static let color: Color = .Tangem.Text.Neutral.tertiary
        }

        enum CryptoBalance {
            static let font = Font.Tangem.Caption12.regular
            static let color: Color = .Tangem.Text.Neutral.tertiary
        }

        enum PriceChange {
            static let font = Font.Tangem.Caption12.regular
        }
    }

    enum Spacings {
        static let priceChangeIconSpacing: CGFloat = SizeUnit.x1.value
        static let badgeSpacing: CGFloat = SizeUnit.x1.value
    }
}
