//
//  AddToPortfolioPromoView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI

struct AddToPortfolioPromoView: View {
    let iconURL: URL
    let action: () -> Void

    @Environment(\.locale) private var locale
    @State private var titleAttributedString: AttributedString

    init(iconURL: URL, action: @escaping () -> Void) {
        self.iconURL = iconURL
        self.action = action
        _titleAttributedString = State(initialValue: MarketsPortfolioPlateTitle.make(
            Localization.marketsPortfolioBlockAddTokenTitle,
            emphasizedColor: Color.Tangem.Text.Neutral.primary
        ))
    }

    private var actionButton: some View {
        Button(action: action) {
            Text(Localization.marketsAddToken)
                .style(Fonts.Bold.subheadline, color: Color.Tangem.Text.Neutral.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Color.Tangem.Button.backgroundSecondary)
                )
        }
        .accessibilityIdentifier(MainAccessibilityIdentifiers.addToPortfolioButton)
    }

    var body: some View {
        MarketsPortfolioPlateView(iconURL: iconURL, title: titleAttributedString) {
            actionButton
        }
        .onChange(of: locale.identifier) { _ in
            titleAttributedString = MarketsPortfolioPlateTitle.make(
                Localization.marketsPortfolioBlockAddTokenTitle,
                emphasizedColor: Color.Tangem.Text.Neutral.primary
            )
        }
    }
}
