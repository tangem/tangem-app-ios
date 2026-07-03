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
            state: Self.applyFractionStyling(state),
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

// MARK: - Fraction styling

private extension TangemPayBalanceView {
    static func applyFractionStyling(_ state: LoadableBalanceView.State) -> LoadableBalanceView.State {
        switch state {
        case .loaded(let text):
            return .loaded(text: styled(text))
        case .loading(let cached):
            return .loading(cached: cached.map(styled))
        case .failed(let cached, let icon):
            return .failed(cached: styled(cached), icon: icon)
        }
    }

    static func styled(_ text: LoadableBalanceView.Text) -> LoadableBalanceView.Text {
        switch text {
        case .string(let raw):
            return .attributed(format(raw))
        case .attributed, .builder:
            return text
        }
    }

    static func format(_ raw: String) -> AttributedString {
        BalanceFormatter().formatAttributedTotalBalance(
            fiatBalance: raw,
            formattingOptions: .init(
                integerPartFont: TangemFontStyle(
                    font: DesignSystem.Font.displayMediumToken.font,
                    tracking: DesignSystem.Font.displayMediumToken.tracking
                ),
                fractionalPartFont: TangemFontStyle(
                    font: DesignSystem.Font.headingMediumToken.font,
                    tracking: DesignSystem.Font.headingMediumToken.tracking
                ),
                integerPartColor: DesignSystem.Color.textPrimary,
                fractionalPartColor: DesignSystem.Color.textPrimary,
                fractionalPartIncludesDecimalSeparator: true
            )
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
