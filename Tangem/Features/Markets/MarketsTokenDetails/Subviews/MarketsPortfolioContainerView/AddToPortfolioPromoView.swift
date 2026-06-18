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
        _titleAttributedString = State(initialValue: Self.makeTitleAttributedString())
    }

    private var actionButton: some View {
        Button(action: action) {
            Text(Localization.marketsAddToken)
                .style(Fonts.Bold.subheadline, color: Color.Tangem.Text.Neutral.primary)
                .padding(.horizontal, Constants.actionButtonHorizontalPadding)
                .padding(.vertical, Constants.actionButtonVerticalPadding)
                .background(
                    Capsule().fill(Color.Tangem.Button.backgroundSecondary)
                )
        }
        .accessibilityIdentifier(MainAccessibilityIdentifiers.addToPortfolioButton)
    }

    var body: some View {
        HStack(spacing: Constants.contentSpacing) {
            IconView(
                url: iconURL,
                size: .init(bothDimensions: Constants.iconSize),
                forceKingfisher: true
            )

            Text(titleAttributedString)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            actionButton
        }
        .padding(.vertical, Constants.contentVerticalPadding)
        .padding(.horizontal, Constants.contentHorizontalPadding)
        .frame(minHeight: Constants.minPlateHeight)
        .background(
            Capsule()
                .fill(Colors.Background.action)
        )
        .onChange(of: locale.identifier) { _ in
            titleAttributedString = Self.makeTitleAttributedString()
        }
    }
}

// MARK: - Constants

private extension AddToPortfolioPromoView {
    static func makeTitleAttributedString() -> AttributedString {
        let raw = Localization.marketsPortfolioBlockAddTokenTitle
        guard var attributed = try? AttributedString(markdown: raw) else {
            return AttributedString(raw)
        }

        for run in attributed.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            attributed[run.range].foregroundColor = Colors.Text.primary1
            attributed[run.range].font = Fonts.Bold.caption1
        }

        return attributed
    }

    enum Constants {
        static let iconSize: CGFloat = 36
        static let contentSpacing: CGFloat = 12
        static let contentVerticalPadding: CGFloat = 12
        static let contentHorizontalPadding: CGFloat = 14
        static let actionButtonHorizontalPadding: CGFloat = 14
        static let actionButtonVerticalPadding: CGFloat = 8
        static let minPlateHeight: CGFloat = 60
    }
}
