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
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct MarketsTokenDetailsListedOnExchangesViewRedesign: View {
    let exchangesCount: Int
    let buttonAction: () -> Void

    private var isListedOnExchanges: Bool {
        exchangesCount > 0
    }

    var body: some View {
        if isListedOnExchanges {
            SwiftUI.Button(action: buttonAction) {
                rowContent
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.listedOnExchanges)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.marketsTokenDetailsListedOn)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
                    .accessibilityIdentifier(MarketsAccessibilityIdentifiers.listedOnExchangesTitle)

                Group {
                    if isListedOnExchanges {
                        Text(Localization.marketsTokenDetailsAmountExchanges(exchangesCount))
                    } else {
                        Text(Localization.marketsTokenDetailsEmptyExchanges)
                            .accessibilityIdentifier(MarketsAccessibilityIdentifiers.listedOnExchangesEmptyText)
                    }
                }
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
            }

            Spacer(minLength: .zero)

            if isListedOnExchanges {
                DesignSystem.Icons.ChevronRight.regular24.image
                    .renderingMode(.template)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
            }
        }
        .roundedBackground(with: DesignSystem.Color.bgSecondary, padding: 16, radius: 24)
        .contentShape(.rect)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 20) {
        MarketsTokenDetailsListedOnExchangesViewRedesign(exchangesCount: 244, buttonAction: {})

        MarketsTokenDetailsListedOnExchangesViewRedesign(exchangesCount: 0, buttonAction: {})
    }
    .padding()
    .background(DesignSystem.Color.bgPrimary)
}
