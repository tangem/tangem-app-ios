//
//  PolymarketOrderMarketRow.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketOrderMarketRow: View {
    private let model: Model
    private var backgroundColor: Color = DesignSystem.Color.bgSecondary

    public init(model: Model) {
        self.model = model
    }

    public func backgroundColor(_ color: Color) -> Self {
        var view = self
        view.backgroundColor = color

        return view
    }

    public var body: some View {
        TangemUI.Row(title: model.question)
            .titleLineLimit(Constants.titleLineLimit)
            .verticalAlignment(.center)
            .end { PolymarketAvatarView(url: model.imageURL) }
            .extraBottom {
                PolymarketOutcomeVoteView(
                    outcomeTitle: model.outcomeTitle,
                    priceText: model.outcomePriceText,
                    nextPriceText: model.outcomeNextPriceText,
                    isNextPriceLoading: model.isOutcomeNextPriceLoading,
                    style: model.outcomeStyle
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }
}

// MARK: - Constants

private extension PolymarketOrderMarketRow {
    enum Constants {
        static let titleLineLimit = 2
        static let cornerRadius: CGFloat = 24
    }
}
