//
//  PolymarketEventCardModel.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension PolymarketEventCard {
    enum Variant: Hashable {
        case multiMarket
        case singleMarket
    }

    struct Model {
        public let id: String

        public let title: String
        public let category: Category?
        public let volumeText: String?
        public let imageURL: URL?
        public let variant: Variant
        public let rows: [Row]
        public let additionalOutcomesCount: Int
        public let isInActivePredicts: Bool
        public let isLive: Bool

        public init(
            id: String,
            title: String,
            category: Category?,
            volumeText: String?,
            imageURL: URL?,
            variant: Variant,
            rows: [Row],
            additionalOutcomesCount: Int,
            isInActivePredicts: Bool,
            isLive: Bool = false
        ) {
            self.id = id
            self.title = title
            self.category = category
            self.volumeText = volumeText
            self.imageURL = imageURL
            self.variant = variant
            self.rows = rows
            self.additionalOutcomesCount = additionalOutcomesCount
            self.isInActivePredicts = isInActivePredicts
            self.isLive = isLive
        }
    }

    typealias Category = PolymarketMarketMetaRow.Category

    struct Row: Identifiable {
        public let id: String
        public let title: String?
        public let subtitle: String?
        public let outcomes: [Outcome]

        public init(id: String, title: String?, subtitle: String?, outcomes: [Outcome]) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.outcomes = outcomes
        }
    }

    struct Outcome: Identifiable {
        public let id: String
        public let title: String
        public let priceText: String?
        public let style: PolymarketOutcomeStyle
        public let onSelect: () -> Void

        public init(
            id: String,
            title: String,
            priceText: String? = nil,
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
