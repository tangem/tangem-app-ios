//
//  OnrampCurrencyView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct OnrampCurrencyView: View {
    let data: OnrampCurrencyViewData

    var body: some View {
        SwiftUI.Button(action: data.action) {
            labelView
        }
        .accessibilityIdentifier(OnrampAccessibilityIdentifiers.currencyItem(code: data.code))
    }

    private var labelView: some View {
        HStack(alignment: .center, spacing: .zero) {
            IconView(
                url: data.image,
                size: .init(bothDimensions: 36)
            )
            .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(data.code)
                    .style(Fonts.Bold.subheadline, color: DesignSystem.Color.textPrimary)

                Text(data.name)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: DesignSystem.Color.textSecondary)
            }
            .padding(.trailing, 6)

            Spacer()

            if data.isSelected {
                Assets.checkmark20.image
                    .resizable()
                    .frame(size: .init(bothDimensions: 24))
                    .foregroundColor(DesignSystem.Color.iconAccentBlue)
            }
        }
        .padding(.vertical, 14)
    }
}
