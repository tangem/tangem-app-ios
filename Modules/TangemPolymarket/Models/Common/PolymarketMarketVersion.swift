//
//  PolymarketMarketVersion.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketMarketVersion: Hashable, Sendable {
    case v1
    case v2
    case unknown(String?)

    public init(apiValue: String?) {
        switch apiValue?.lowercased() {
        case "v1": self = .v1
        case "v2": self = .v2
        case let value: self = .unknown(value)
        }
    }

    public var isSupported: Bool {
        switch self {
        case .v1, .v2: true
        case .unknown: false
        }
    }
}
