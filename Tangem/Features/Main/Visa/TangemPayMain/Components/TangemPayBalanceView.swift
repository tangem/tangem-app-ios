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
    var isError: Bool = false

    var body: some View {
        LoadableBalanceView(
            state: AttributedBalanceFormatter.decimalColored(
                state,
                integerFont: TangemFontStyle(DesignSystem.Font.displayMediumToken),
                fractionalFont: TangemFontStyle(DesignSystem.Font.headingMediumToken),
                integerColor: isError ? DesignSystem.Color.textStatusError : DesignSystem.Color.textPrimary,
                fractionalColor: isError ? DesignSystem.Color.textStatusError : DesignSystem.Color.textSecondary
            ),
            style: .init(
                font: DesignSystem.Font.displayMediumToken.font,
                textColor: isError ? DesignSystem.Color.textStatusError : DesignSystem.Color.textPrimary
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
