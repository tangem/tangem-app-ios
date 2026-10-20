//
//  PolymarketActivityDetailsView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketActivityDetailsView: View {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            summary

            if !model.rows.isEmpty {
                PolymarketDetailsRowsBlock(rows: model.rows)
                    .padding(.top, Constants.rowsTopPadding)
                    .padding(.horizontal, Constants.horizontalPadding)
            }
        }
    }

    public static func header(model: Model, onClose: @escaping () -> Void) -> some View {
        HStack(spacing: Constants.headerSpacing) {
            DesignSystem.Icons.Success.regular20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: Constants.statusIconSide, height: Constants.statusIconSide)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(width: Constants.statusSide, height: Constants.statusSide)
                .background(DesignSystem.Color.bgTransparentSecondary, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Constants.headerTextSpacing) {
                Text(model.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                Text(model.date)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            NavigationBarButton.close(action: onClose)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.headerVerticalPadding)
    }

    private var summary: some View {
        VStack(spacing: Constants.summarySpacing) {
            PolymarketActivityIcon(icon: model.icon, side: Constants.iconSide, glyphSide: Constants.glyphSide)

            VStack(spacing: Constants.textSpacing) {
                ForEach(model.headlines, id: \.self) { headline in
                    Text(headline)
                        .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                }

                if let question = model.question {
                    Text(question)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                }

                if let outcome = model.outcome {
                    // [REDACTED_TODO_COMMENT]
                    PolymarketOutcomeBubble(prefix: "Your bet", title: outcome.title, style: outcome.style, palette: .bet)
                        .padding(.top, Constants.bubbleTopPadding)
                        .padding(.bottom, Constants.bubbleBottomPadding)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Constants.summaryTopPadding)
        .padding(.bottom, Constants.summaryBottomPadding)
        .padding(.horizontal, Constants.summaryHorizontalPadding)
    }

    public static func footer(onGoToPredict action: @escaping () -> Void) -> some View {
        // [REDACTED_TODO_COMMENT]
        TangemUI.Button(label: "Go to Predict", accessibilityLabel: nil, action: action)
            .styleType(.secondary(.default))
            .size(.x12)
            .horizontalLayout(.infinity)
            .padding(Constants.horizontalPadding)
    }
}

// MARK: - Model

public extension PolymarketActivityDetailsView {
    struct Model: Hashable {
        public let title: String
        public let date: String
        public let icon: PolymarketActivityRow.Icon
        public let headlines: [String]
        public let question: String?
        public let outcome: Outcome?
        public let rows: [PolymarketDetailsRowsBlock.Row]

        public init(
            title: String,
            date: String,
            icon: PolymarketActivityRow.Icon,
            headlines: [String],
            question: String?,
            outcome: Outcome?,
            rows: [PolymarketDetailsRowsBlock.Row]
        ) {
            self.title = title
            self.date = date
            self.icon = icon
            self.headlines = headlines
            self.question = question
            self.outcome = outcome
            self.rows = rows
        }
    }

    struct Outcome: Hashable {
        public let title: String
        public let style: PolymarketOutcomeStyle

        public init(title: String, style: PolymarketOutcomeStyle) {
            self.title = title
            self.style = style
        }
    }
}

// MARK: - Constants

private extension PolymarketActivityDetailsView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let headerSpacing: CGFloat = 12
        static let headerVerticalPadding: CGFloat = 12
        static let headerTextSpacing: CGFloat = 4
        static let statusSide: CGFloat = 44
        static let statusIconSide: CGFloat = 20
        static let iconSide: CGFloat = 72
        static let glyphSide: CGFloat = 32
        static let summarySpacing: CGFloat = 24
        static let textSpacing: CGFloat = 4
        static let summaryTopPadding: CGFloat = 48
        static let summaryBottomPadding: CGFloat = 24
        static let summaryHorizontalPadding: CGFloat = 56
        static let bubbleTopPadding: CGFloat = 12
        static let bubbleBottomPadding: CGFloat = 4
        static let rowsTopPadding: CGFloat = 12
    }
}

// MARK: - Previews

#Preview {
    PolymarketActivityDetailsView(
        model: .init(
            title: "Bought",
            date: "Jul 9, 2026 • 14:32",
            icon: .market(nil),
            headlines: ["-$166.84"],
            question: "Will Uzbekistan win the 2026 FIFA World Cup?",
            outcome: .init(title: "Yes", style: .affirmative),
            rows: [
                .init(title: "Qty of Tokens", value: "248.50"),
                .init(title: "Price", value: "$0.67"),
                .init(title: "Fee", value: "$0.55"),
                .init(title: "Notional Gross", value: "$166.50"),
            ]
        )
    )
    .background(DesignSystem.Color.bgSecondary)
}
