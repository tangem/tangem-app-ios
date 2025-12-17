//
//  MarketsTokenDetailsListedOnExchangesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

struct MarketsTokenDetailsListedOnExchangesView: View {
    let exchangesCount: Int
    let buttonAction: () -> Void

    private var isListedOnExchanges: Bool {
        exchangesCount > 0
    }

    var body: some View {
        Group {
            if isListedOnExchanges {
                Button(
                    action: buttonAction,
                    label: {
                        content
                    }
                )
                .accessibilityIdentifier(
                    MarketsAccessibilityIdentifiers.listedOnExchanges)
            } else {
                content
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.marketsTokenDetailsListedOn)
                    .style(Fonts.Bold.footnote.weight(.semibold), color: Colors.Text.tertiary)
                    .accessibilityIdentifier(
                        MarketsAccessibilityIdentifiers.listedOnExchangesTitle)

                Group {
                    if isListedOnExchanges {
                        Text(Localization.marketsTokenDetailsAmountExchanges(exchangesCount))
                    } else {
                        Text(Localization.marketsTokenDetailsEmptyExchanges)
                            .accessibilityIdentifier(
                                MarketsAccessibilityIdentifiers.listedOnExchangesEmptyText)
                    }
                }
                .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }

            Spacer()

            if isListedOnExchanges {
                Assets.chevronRightWithOffset24.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.informative)
            }
        }
    }
}

#Preview {
    VStack {
        MarketsTokenDetailsListedOnExchangesView(exchangesCount: 10, buttonAction: {})

        MarketsTokenDetailsListedOnExchangesView(exchangesCount: 0, buttonAction: {})
    }
}
