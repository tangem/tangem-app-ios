//
//  PolymarketSearchRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct PolymarketSearchRequest: Hashable, Sendable {
    public let query: String
    public let limit: Int?

    public let page: Int?

    public init(query: String, limit: Int? = nil, page: Int? = nil) {
        self.query = query
        self.limit = limit
        self.page = page
    }
}
