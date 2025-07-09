//
//  SendNewAmountTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendNewAmountTokenView: View {
    let data: SendNewAmountTokenViewData

    var body: some View {
        HStack(spacing: 14) {
            switch (data.action, data.detailsType) {
            case (.some(let leadingAction), .select(_, individualAction: .some(let individualAction))):
                Button(action: leadingAction) {
                    leadingView

                    Spacer()
                }

                Button(action: individualAction) { trailingView }
            case (.some(let leadingAction), _):
                Button(action: leadingAction) {
                    leadingView

                    Spacer()

                    trailingView
                }
            case (.none, _):
                leadingView

                Spacer()

                trailingView
            }
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
        case .select(.some(let amount), _):
            HStack(spacing: 4) {
                Text(amount)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Assets.Glyphs.selectIcon.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Colors.Text.tertiary)
                    .frame(width: 18, height: 24)
            }
        case .select(.none, .none):
            Assets.Glyphs.selectIcon.image
        case .select(.none, .some):
            HStack(spacing: 8) {
                // Expand tappable area
                FixedSpacer(width: 20)

                Assets.Glyphs.selectIcon.image
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Colors.Text.tertiary)
                    .frame(width: 18, height: 24)
            }
        }
    }
}

#Preview {
    SendNewAmountTokenView(
        data: .init(
            tokenIconInfo: TokenIconInfoBuilder().build(
                for: .token(value: .polygonTokenMock),
                in: .polygon(testnet: false),
                isCustom: false
            ),
            title: "Polygon",
            subtitle: "Will be send to recepient",
            detailsType: .none,
            action: {}
        )
    )
}
