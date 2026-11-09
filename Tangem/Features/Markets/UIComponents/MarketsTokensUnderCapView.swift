//
//  MarketsTokensUnderCapView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

struct MarketsTokensUnderCapView: View {
    // MARK: - Properties

    let onShowUnderCapAction: () -> Void

    // MARK: - View

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: .zero) {
                Text(Localization.marketsSearchSeeTokensUnder100k)
                    .style(Fonts.Regular.footnote, color: DesignSystem.Color.textSecondary)
            }

            HStack(spacing: .zero) {
                Button(action: {
                    onShowUnderCapAction()
                }, label: {
                    HStack(spacing: .zero) {
                        Text(Localization.marketsSearchShowTokens)
                            .style(Fonts.Bold.footnote, color: DesignSystem.Color.textPrimary)
                    }
                })
                .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsTokensUnderCapExpandButton)
                .roundedBackground(with: DesignSystem.Color.bgTransparentSecondary, verticalPadding: 8, horizontalPadding: 14, radius: 10)
            }
        }
        .padding(.vertical, 12)
    }
}
