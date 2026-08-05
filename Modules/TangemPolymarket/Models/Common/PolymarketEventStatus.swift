//
//  PolymarketEventStatus.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum PolymarketEventStatus: Hashable, Sendable {
    case active
    case closed
    case archived
    case unknown(String)

    public init(apiValue: String) {
        switch apiValue {
        case "active": self = .active
        case "closed": self = .closed
        case "archived": self = .archived
        default: self = .unknown(apiValue)
        }
    }
}
