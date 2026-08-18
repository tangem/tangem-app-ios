//
//  PolymarketCLOBAuthHeaders.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketCLOBAuthHeaders: Hashable, Sendable {
    public let values: [String: String]

    public init(values: [String: String]) {
        self.values = values
    }
}
