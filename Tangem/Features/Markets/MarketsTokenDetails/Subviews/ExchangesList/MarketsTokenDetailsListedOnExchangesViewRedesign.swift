//
//  MarketsTokenDetailsListedOnExchangesViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemAccessibilityIdentifiers

struct MarketsTokenDetailsListedOnExchangesViewRedesign: View {
    let exchangesCount: Int
    let buttonAction: () -> Void

    private var isListedOnExchanges: Bool {
        exchangesCount > 0
    }

    var body: some View {
        if isListedOnExchanges {
            Button(action: buttonAction) {
                rowContent
            }
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.listedOnExchanges)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        TangemTwoLineRowLayout(
            primaryLeading: {
                Text(Localization.marketsTokenDetailsListedOn)
                    .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                    .lineLimit(1)
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.listedOnExchangesTitle)
            },
            secondaryLeading: {
                Group {
                    if isListedOnExchanges {
                        Text(Localization.marketsTokenDetailsAmountExchanges(exchangesCount))
                    } else {
                        Text(Localization.marketsTokenDetailsEmptyExchanges)
                            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.listedOnExchangesEmptyText)
                    }
                }
                .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                .lineLimit(1)
            },
            centeredTrailing: {
                if isListedOnExchanges {
                    Assets.Glyphs.chevronRightNew.image
                        .renderingMode(.template)
                        .foregroundStyle(Color.Tangem.Graphic.Neutral.secondary)
                }
            }
        )
        .roundedBackground(with: .Tangem.Surface.level3, padding: .unit(.x4), radius: .unit(.x6))
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        MarketsTokenDetailsListedOnExchangesViewRedesign(exchangesCount: 244, buttonAction: {})

        MarketsTokenDetailsListedOnExchangesViewRedesign(exchangesCount: 0, buttonAction: {})
    }
    .padding()
    .background(Color.Tangem.Surface.level1)
}
#endif // DEBUG
