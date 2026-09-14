//
//  PolymarketBridgeAddresses.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketBridgeAddresses: Hashable, Sendable {
    private let addresses: [PolymarketChainFamily: String]

    public init(addresses: [PolymarketChainFamily: String]) {
        self.addresses = addresses
    }

    public func address(for family: PolymarketChainFamily) -> String? {
        addresses[family]
    }
}
