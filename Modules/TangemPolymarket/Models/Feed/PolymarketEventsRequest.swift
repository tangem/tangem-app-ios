//
//  PolymarketEventsRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct PolymarketEventsRequest: Hashable, Sendable {
    public let category: Int?
    public let filter: PolymarketCategoryFilter?
    public let sort: PolymarketEventsSort?
    public let ascending: Bool?
    public let limit: Int?

    public let cursor: String?

    public init(
        category: Int? = nil,
        filter: PolymarketCategoryFilter? = nil,
        sort: PolymarketEventsSort? = nil,
        ascending: Bool? = nil,
        limit: Int? = nil,
        cursor: String? = nil
    ) {
        self.category = category
        self.filter = filter
        self.sort = sort
        self.ascending = ascending
        self.limit = limit
        self.cursor = cursor
    }
}
