//
//  PolymarketOrderSummaryHeader.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

public struct PolymarketOrderSummaryHeader: View {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Constants.blockSpacing) {
            source

            amount
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Color.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private var source: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Constants.sourceSpacing) {
                Text(model.sourceTitle)

                HStack(spacing: Constants.lineSpacing) {
                    model.accountIcon.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.accountIconSide, height: Constants.accountIconSide)
                        .accessibilityHidden(true)

                    Text(model.accountName)
                }
            }

            Text(model.balanceText)
        }
        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        .lineLimit(1)
    }

    private var amount: some View {
        HStack(alignment: .top, spacing: Constants.amountSpacing) {
            VStack(alignment: .leading, spacing: Constants.lineSpacing) {
                Text(model.amountText)
                    .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(Constants.amountMinScale)

                if let caption = model.caption {
                    Text(caption)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)
                } else if let toWin = model.toWin {
                    PolymarketAmountBadge.toWin(state: toWin)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            model.accountIcon.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.amountIconSide, height: Constants.amountIconSide)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderSummaryHeader {
    enum Constants {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let blockSpacing: CGFloat = 20
        static let sourceSpacing: CGFloat = 6
        static let lineSpacing: CGFloat = 4
        static let amountSpacing: CGFloat = 12
        static let accountIconSide: CGFloat = 16
        static let amountMinScale: CGFloat = 0.5
        static let amountIconSide: CGFloat = 36
    }
}
