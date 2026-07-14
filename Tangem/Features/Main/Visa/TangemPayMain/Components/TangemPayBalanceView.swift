//
//  TangemPayBalanceView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct TangemPayBalanceView: View {
    let state: LoadableBalanceView.State

    var body: some View {
        LoadableBalanceView(
            state: AttributedBalanceFormatter.decimalColored(
                state,
                integerFont: TangemFontStyle(DesignSystem.Font.displayMediumToken),
                fractionalFont: TangemFontStyle(DesignSystem.Font.headingMediumToken),
                integerColor: DesignSystem.Color.textPrimary,
                fractionalColor: DesignSystem.Color.textSecondary
            ),
            style: .init(
                font: DesignSystem.Font.displayMediumToken.font,
                textColor: DesignSystem.Color.textPrimary
            ),
            loader: .init(
                size: CGSize(width: 140, height: 44),
                cornerRadius: 8
            ),
            accessibilityIdentifier: TangemPayAccessibilityIdentifiers.paymentAccountBalance
        )
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        TangemPayBalanceView(state: .loaded(text: "$18.97"))
        TangemPayBalanceView(state: .loading(cached: .string("$18.97")))
        TangemPayBalanceView(state: .loading())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}
