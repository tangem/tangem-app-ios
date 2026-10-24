//
//  PolymarketOrderMarketRowModel.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension PolymarketOrderMarketRow {
    struct Model {
        public let question: String
        public let imageURL: URL?
        public let outcomeTitle: String
        public let outcomePriceText: String
        public let outcomeNextPriceText: String?
        public let isOutcomeNextPriceLoading: Bool
        public let outcomeStyle: PolymarketOutcomeStyle

        public init(
            question: String,
            imageURL: URL?,
            outcomeTitle: String,
            outcomePriceText: String,
            outcomeNextPriceText: String? = nil,
            isOutcomeNextPriceLoading: Bool = false,
            outcomeStyle: PolymarketOutcomeStyle
        ) {
            self.question = question
            self.imageURL = imageURL
            self.outcomeTitle = outcomeTitle
            self.outcomePriceText = outcomePriceText
            self.outcomeNextPriceText = outcomeNextPriceText
            self.isOutcomeNextPriceLoading = isOutcomeNextPriceLoading
            self.outcomeStyle = outcomeStyle
        }

        public func settling(nextPriceText: String?, isLoading: Bool) -> Self {
            Self(
                question: question,
                imageURL: imageURL,
                outcomeTitle: outcomeTitle,
                outcomePriceText: outcomePriceText,
                outcomeNextPriceText: nextPriceText == outcomePriceText ? nil : nextPriceText,
                isOutcomeNextPriceLoading: isLoading,
                outcomeStyle: outcomeStyle
            )
        }
    }
}
