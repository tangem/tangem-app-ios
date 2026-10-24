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
        public let title: String?
        public let category: PolymarketMarketMetaRow.Category?
        public let volumeText: String?
        public let imageURL: URL?
        public let predictedText: String?
        public let outcomes: [Outcome]

        public init(
            id: String,
            title: String?,
            category: PolymarketMarketMetaRow.Category? = nil,
            volumeText: String?,
            imageURL: URL?,
            predictedText: String?,
            outcomes: [Outcome]
        ) {
            self.id = id
            self.title = title
            self.category = category
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
        public let isEnabled: Bool
        public let onSelect: () -> Void

        public init(
            id: String,
            title: String,
            priceText: String,
            style: PolymarketOutcomeStyle,
            isEnabled: Bool = true,
            onSelect: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.priceText = priceText
            self.style = style
            self.isEnabled = isEnabled
            self.onSelect = onSelect
        }
    }
}
