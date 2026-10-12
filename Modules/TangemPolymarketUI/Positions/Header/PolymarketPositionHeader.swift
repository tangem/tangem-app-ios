//
//  PolymarketPositionHeader.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketPositionHeader: View {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: Constants.iconSpacing) {
            PolymarketAvatarView(url: model.iconURL, side: Constants.iconSide)

            VStack(spacing: Constants.textSpacing) {
                change

                Text(model.valueText)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                Text(model.question)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(Constants.questionLineLimit)

                badges
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.padding)
    }

    private var change: some View {
        HStack(spacing: Constants.changeSpacing) {
            model.changeType.imageType.image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.changeIconSide, height: Constants.changeIconSide)
                .foregroundStyle(model.changeType.iconColor)

            Text(model.changeText)
                .style(DesignSystem.Font.headingMediumToken, color: model.changeType.color)
                .lineLimit(1)
        }
    }

    private var badges: some View {
        HStack(spacing: Constants.badgeSpacing) {
            PolymarketOutcomePill(title: model.outcomeTitle, style: model.outcomeStyle)

            if let payoutAmount = model.payoutAmount {
                PolymarketAmountBadge.payout(state: .value(payoutAmount))
            }

            if let status = model.status {
                Badge(label: status.text, accessibilityLabel: nil)
                    .size(.x6)
                    .variant(status.variant)
                    .appearance(status.appearance)
                    .slotStart(status.icon)
            }
        }
        .padding(.top, Constants.badgeTopSpacing)
    }
}

// MARK: - Model

public extension PolymarketPositionHeader {
    struct Model {
        public let iconURL: URL?
        public let changeText: String
        public let changeType: PriceChangeView.ChangeType
        public let valueText: String
        public let question: String
        public let outcomeTitle: String
        public let outcomeStyle: PolymarketOutcomeStyle
        public let payoutAmount: String?
        public let status: PolymarketPositionRow.Status?

        public init(
            iconURL: URL?,
            changeText: String,
            changeType: PriceChangeView.ChangeType,
            valueText: String,
            question: String,
            outcomeTitle: String,
            outcomeStyle: PolymarketOutcomeStyle,
            payoutAmount: String?,
            status: PolymarketPositionRow.Status? = nil
        ) {
            self.iconURL = iconURL
            self.changeText = changeText
            self.changeType = changeType
            self.valueText = valueText
            self.question = question
            self.outcomeTitle = outcomeTitle
            self.outcomeStyle = outcomeStyle
            self.payoutAmount = payoutAmount
            self.status = status
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionHeader {
    enum Constants {
        static let iconSide: CGFloat = 72
        static let iconSpacing: CGFloat = 24
        static let textSpacing: CGFloat = 4
        static let changeSpacing: CGFloat = 2
        static let changeIconSide: CGFloat = 12
        static let badgeSpacing: CGFloat = 4
        static let badgeTopSpacing: CGFloat = 4
        static let padding: CGFloat = 24
        static let questionLineLimit = 2
    }
}
