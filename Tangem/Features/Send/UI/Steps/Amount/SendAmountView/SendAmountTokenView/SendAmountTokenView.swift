//
//  SendAmountTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct SendAmountTokenView: View {
    let data: SendAmountTokenViewData

    var body: some View {
        HStack(spacing: 14) {
            switch (data.action, data.detailsType) {
            case (.some(let leadingAction), .select(individualAction: .some(let individualAction))):
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

                switch data.subtitle {
                case .balance(let state):
                    LoadableBalanceView(
                        state: state,
                        style: .init(font: Fonts.Regular.caption1, textColor: Colors.Text.tertiary),
                        loader: .init(size: CGSize(width: 130, height: 15))
                    )
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.balanceLabel)
                case .receive(let state):
                    LoadableTextView(
                        state: state,
                        font: Fonts.Regular.caption1,
                        textColor: Colors.Text.tertiary,
                        loaderSize: CGSize(width: 130, height: 15)
                    )
                }
            }
        }
        .infinityFrame(axis: .horizontal, alignment: .leading)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    var trailingView: some View {
        switch data.detailsType {
        case .none:
            EmptyView()
        case .max(let action):
            CapsuleButton(title: Localization.sendMaxAmount, action: action)
                .accessibilityIdentifier(SendAccessibilityIdentifiers.maxAmountButton)
        case .select(.none):
            Assets.Glyphs.selectIcon.image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Colors.Text.tertiary)
                .frame(width: 18, height: 24)
        case .select(.some):
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
    SendAmountTokenView(
        data: .init(
            tokenIconInfo: TokenIconInfoBuilder().build(
                for: .token(value: .polygonTokenMock),
                in: .polygon(testnet: false),
                isCustom: false
            ),
            title: "Polygon",
            subtitle: .receive(state: .loaded(text: "Will be send to recepient")),
            detailsType: .none,
            action: {}
        )
    )
}
