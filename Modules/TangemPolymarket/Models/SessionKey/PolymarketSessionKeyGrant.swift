//
//  PolymarketSessionKeyGrant.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketSessionKeyGrant: Hashable, Sendable {
    public let sessionKeyAddress: String
    public let validUntil: Date
    public let call: PolymarketRelayedBatch.Call
}
