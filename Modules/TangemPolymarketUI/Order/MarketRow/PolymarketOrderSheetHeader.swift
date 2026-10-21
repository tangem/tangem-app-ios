//
//  PolymarketOrderSheetHeader.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketOrderSheetHeader: View {
    private let model: PolymarketOrderMarketRow.Model
    private let onClose: () -> Void

    public init(model: PolymarketOrderMarketRow.Model, onClose: @escaping () -> Void) {
        self.model = model
        self.onClose = onClose
    }

    public var body: some View {
        HStack(spacing: Constants.spacing) {
            PolymarketAvatarView(url: model.imageURL, side: Constants.avatarSide)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(model.question)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                    .lineLimit(1)

                PolymarketOutcomeVoteView(
                    outcomeTitle: model.outcomeTitle,
                    priceText: model.outcomePriceText,
                    nextPriceText: model.outcomeNextPriceText,
                    isNextPriceLoading: model.isOutcomeNextPriceLoading,
                    style: model.outcomeStyle
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            TopNavigationActions(actions: .one(.close(action: onClose)))
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(minHeight: Constants.minHeight)
    }
}

// MARK: - Constants

private extension PolymarketOrderSheetHeader {
    enum Constants {
        static let spacing: CGFloat = 8
        static let textSpacing: CGFloat = 4
        static let avatarSide: CGFloat = 40
        static let horizontalPadding: CGFloat = 16
        static let minHeight: CGFloat = 44
    }
}
