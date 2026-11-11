//
//  PolymarketSessionKeyGrant.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketSessionKeyGrant: Hashable, Sendable, Codable {
    public let sessionKeyAddress: String
    public let validUntil: Date
    public let call: PolymarketRelayedBatch.Call

    public init(sessionKeyAddress: String, validUntil: Date, call: PolymarketRelayedBatch.Call) {
        self.sessionKeyAddress = sessionKeyAddress
        self.validUntil = validUntil
        self.call = call
    }
}
