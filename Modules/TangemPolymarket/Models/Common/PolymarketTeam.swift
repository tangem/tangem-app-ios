//
//  PolymarketTeam.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketTeam: Hashable, Sendable {
    public let name: String
    public let abbreviation: String?
    public let alias: String?
    public let logoURL: URL?
    public let side: Side?

    public init(name: String, abbreviation: String?, alias: String?, logoURL: URL?, side: Side?) {
        self.name = name
        self.abbreviation = abbreviation
        self.alias = alias
        self.logoURL = logoURL
        self.side = side
    }
}

// MARK: - Side

public extension PolymarketTeam {
    enum Side: String, Hashable, Sendable {
        case home
        case away
    }
}
