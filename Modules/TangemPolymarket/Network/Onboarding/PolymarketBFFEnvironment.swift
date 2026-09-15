//
//  PolymarketBFFEnvironment.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketBFFEnvironment {
    static let walletIdHeader = "wallet-id"

    public let baseURL: URL
    public let headers: [String: String]

    public init(baseURL: URL, headers: [String: String]) {
        self.baseURL = baseURL
        self.headers = headers
    }

    func requestHeaders(walletId: String) -> [String: String] {
        headers.merging([Self.walletIdHeader: walletId]) { _, walletId in walletId }
    }
}
