//
//  PolymarketPositionsPageRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketPositionsPageRequest<Sort: RawRepresentable & Hashable & Sendable>: Hashable, Sendable where Sort.RawValue == String {
    case first(limit: Int, sort: Sort? = nil, ascending: Bool? = nil)
    case next(cursor: String)

    public static func page(limit: Int, cursor: String?) -> Self {
        cursor.map { .next(cursor: $0) } ?? .first(limit: limit)
    }
}

extension PolymarketPositionsPageRequest {
    var queryParameters: [String: Any] {
        switch self {
        case .first(let limit, let sort, let ascending):
            var parameters: [String: Any] = [PolymarketPositionsPageQuery.limitKey: limit]

            if let sort {
                parameters[PolymarketPositionsPageQuery.sortKey] = sort.rawValue
            }

            if let ascending {
                parameters[PolymarketPositionsPageQuery.ascendingKey] = ascending
            }

            return parameters
        case .next(let cursor):
            return [PolymarketPositionsPageQuery.cursorKey: cursor]
        }
    }
}

private enum PolymarketPositionsPageQuery {
    static let limitKey = "limit"
    static let sortKey = "sort"
    static let ascendingKey = "ascending"
    static let cursorKey = "cursor"
}
