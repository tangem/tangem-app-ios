//
//  TokenRowGlyph.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct TokenRowGlyph: View {
    private let icon: ImageType
    private let color: Color

    @ScaledMetric private var size: CGFloat

    init(icon: ImageType, color: Color, size: CGFloat) {
        self.icon = icon
        self.color = color
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(size: CGSize(bothDimensions: size))
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}

// MARK: - Presets

extension TokenRowGlyph {
    static func balanceIndicator(_ indicator: TokenRow.BalanceIndicator) -> TokenRowGlyph {
        switch indicator {
        case .approveNeeded:
            TokenRowGlyph(
                icon: DesignSystem.Icons.Warning.filled20,
                color: DesignSystem.Color.iconStatusWarning,
                size: TokenRowMetrics.balanceIndicatorSize
            )
        }
    }

    static var staleBalance: TokenRowGlyph {
        TokenRowGlyph(
            icon: DesignSystem.Icons.CloudExclamation.regular20,
            color: DesignSystem.Color.iconPrimary,
            size: TokenRowMetrics.balanceIndicatorSize
        )
    }

    static func trailing(_ icon: ImageType) -> TokenRowGlyph {
        TokenRowGlyph(
            icon: icon,
            color: DesignSystem.Color.iconTertiary,
            size: TokenRowMetrics.trailingIconSize
        )
    }
}
