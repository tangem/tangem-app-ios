//
//  PolymarketCategoryFilter.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketCategoryFilter: Hashable, Sendable {
    case games
    case props
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .games: "games"
        case .props: "props"
        case .unknown(let rawValue): rawValue
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "games": self = .games
        case "props": self = .props
        default: self = .unknown(rawValue)
        }
    }
}
