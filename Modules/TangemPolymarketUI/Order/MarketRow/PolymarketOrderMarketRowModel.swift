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
        public let outcomeStyle: PolymarketOutcomeStyle

        public init(
            question: String,
            imageURL: URL?,
            outcomeTitle: String,
            outcomePriceText: String,
            outcomeStyle: PolymarketOutcomeStyle
        ) {
            self.question = question
            self.imageURL = imageURL
            self.outcomeTitle = outcomeTitle
            self.outcomePriceText = outcomePriceText
            self.outcomeStyle = outcomeStyle
        }
    }
}
