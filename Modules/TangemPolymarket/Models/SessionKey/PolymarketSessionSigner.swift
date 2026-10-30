//
//  PolymarketSessionSigner.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketSessionSigner: Hashable, Sendable {
    public let address: String
    public let scopes: [String]
    public let validUntil: Date?

    public init(address: String, scopes: [String], validUntil: Date?) {
        self.address = address
        self.scopes = scopes
        self.validUntil = validUntil
    }
}
