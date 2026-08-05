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
import TangemUIUtils

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
            emphasizedColor: DesignSystem.Color.textPrimary
        ))
    }

    private var actionButton: some View {
        TangemUI.Button(
            label: AttributedString(Localization.marketsAddToken),
            accessibilityLabel: Localization.marketsAddToken,
            action: action
        )
        .size(.x9)
        .styleType(.secondary)
        .accessibilityIdentifier(MainAccessibilityIdentifiers.addToPortfolioButton)
    }

    var body: some View {
        MarketsPortfolioPlateView(iconURL: iconURL, title: titleAttributedString) {
            actionButton
        }
        .onChange(of: locale.identifier) { _ in
            titleAttributedString = MarketsPortfolioPlateTitle.make(
                Localization.marketsPortfolioBlockAddTokenTitle,
                emphasizedColor: DesignSystem.Color.textPrimary
            )
        }
    }
}
