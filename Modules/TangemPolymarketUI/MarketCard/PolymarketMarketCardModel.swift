//
//  PolymarketMarketCardModel.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension PolymarketMarketCard {
    struct Model: Identifiable {
        public let id: String
        public let title: String
        public let volumeText: String?
        public let imageURL: URL?
        public let predictedText: String?
        public let outcomes: [Outcome]

        public init(
            id: String,
            title: String,
            volumeText: String?,
            imageURL: URL?,
            predictedText: String?,
            outcomes: [Outcome]
        ) {
            self.id = id
            self.title = title
            self.volumeText = volumeText
            self.imageURL = imageURL
            self.predictedText = predictedText
            self.outcomes = outcomes
        }
    }

    struct Outcome: Identifiable {
        public let id: String
        public let title: String
        public let priceText: String
        public let style: PolymarketOutcomeStyle
        public let onSelect: () -> Void

        public init(
            id: String,
            title: String,
            priceText: String,
            style: PolymarketOutcomeStyle,
            onSelect: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.priceText = priceText
            self.style = style
            self.onSelect = onSelect
        }
    }
}
