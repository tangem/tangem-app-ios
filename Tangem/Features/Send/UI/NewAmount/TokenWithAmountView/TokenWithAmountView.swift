//
//  TokenWithAmountView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TokenWithAmountView: View {
    let data: TokenWithAmountViewData

    var body: some View {
        HStack(spacing: 14) {
            if let action = data.action {
                Button(action: action) { leadingView }
            } else {
                leadingView
            }

            Spacer()

            // Trailing has it is own tappable area
            trailingView
        }
    }

    @ViewBuilder
    var leadingView: some View {
        HStack(spacing: 14) {
            TokenIcon(
                tokenIconInfo: data.tokenIconInfo,
                size: CGSize(width: 36, height: 36)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(data.subtitle)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }
        }
    }

    @ViewBuilder
    var trailingView: some View {
        switch data.detailsType {
        case .none:
            EmptyView()
        case .loading:
            ProgressView()
        case .max(let action):
            RoundedButton(title: Localization.sendMaxAmount, action: action)
        case .amount(let amount):
            Text(amount)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
        case .select(.some(let amount), let action):
            Button(action: action) {
                HStack(spacing: 4) {
                    Text(amount)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Assets.Glyphs.selectIcon.image
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Colors.Text.tertiary)
                        .frame(width: 18, height: 24)
                }
            }
        case .select(.none, let action):
            Button(action: action) {
                HStack(spacing: 8) {
                    // Expand tappable area
                    FixedSpacer(width: 20)

                    Assets.Glyphs.selectIcon.image
                }
            }
        }
    }
}

#Preview {
    TokenWithAmountView(
        data: .init(
            tokenIconInfo: TokenIconInfoBuilder().build(
                for: .token(value: .polygonTokenMock),
                in: .polygon(testnet: false),
                isCustom: false
            ),
            title: "Polygon",
            subtitle: "Will be send to recepient",
            detailsType: .none
        )
    )
}
