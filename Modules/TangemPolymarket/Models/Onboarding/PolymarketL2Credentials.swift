//
//  PolymarketL2Credentials.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketL2Credentials: Hashable, Sendable {
    public let apiKey: String
    public let secret: String
    public let passphrase: String

    public init(apiKey: String, secret: String, passphrase: String) {
        self.apiKey = apiKey
        self.secret = secret
        self.passphrase = passphrase
    }
}
