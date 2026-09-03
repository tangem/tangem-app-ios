//
//  PolymarketBFFEnvironment.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Read per request, because the host and the key follow the environment the tester picks at runtime.
public struct PolymarketBFFEnvironment {
    public let baseURL: URL
    public let headers: [String: String]

    public init(baseURL: URL, headers: [String: String]) {
        self.baseURL = baseURL
        self.headers = headers
    }
}
