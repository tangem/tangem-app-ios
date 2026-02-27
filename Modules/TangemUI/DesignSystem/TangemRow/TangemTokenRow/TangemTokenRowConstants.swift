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
            static let font: Font = .Tangem.subheadline
            static let integerColor: Color = .Tangem.Text.Neutral.primary
            static let decimalColor: Color = .Tangem.Text.Neutral.secondary
        }

        enum TokenPrice {
            static let font: Font = .Tangem.caption1
            static let color: Color = .Tangem.Text.Neutral.tertiary
        }

        enum CryptoBalance {
            static let font: Font = .Tangem.caption1
            static let color: Color = .Tangem.Text.Neutral.tertiary
        }

        enum PriceChange {
            static let font: Font = .Tangem.caption1
        }
    }

    enum Spacings {
        static let priceChangeIconSpacing: CGFloat = SizeUnit.x1.value
        static let badgeSpacing: CGFloat = SizeUnit.x1.value
    }

    enum Sizes {
        static let iconSize: CGFloat = SizeUnit.x9.value
        static let fiatBalanceLoaderSize = CGSize(width: SizeUnit.x10.value, height: SizeUnit.x3.value)
        static let cryptoBalanceLoaderSize = CGSize(width: SizeUnit.x10.value, height: SizeUnit.x3.value)
        static let tokenPriceLoaderSize = CGSize(width: SizeUnit.x13.value, height: SizeUnit.x3.value)
    }
}
