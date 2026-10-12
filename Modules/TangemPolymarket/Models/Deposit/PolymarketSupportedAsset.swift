//
//  PolymarketSupportedAsset.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketSupportedAsset: Hashable, Sendable, Identifiable {
    public let chainId: String
    public let chainName: String
    public let family: PolymarketChainFamily
    public let token: Token
    public let minCheckoutUSD: Decimal

    public var id: ID {
        ID(chainId: chainId, tokenAddress: token.address)
    }

    public init(
        chainId: String,
        chainName: String,
        family: PolymarketChainFamily,
        token: Token,
        minCheckoutUSD: Decimal
    ) {
        self.chainId = chainId
        self.chainName = chainName
        self.family = family
        self.token = token
        self.minCheckoutUSD = minCheckoutUSD
    }
}

// MARK: - Nested types

public extension PolymarketSupportedAsset {
    struct Token: Hashable, Sendable {
        public let name: String
        public let symbol: String
        public let address: String
        public let decimalCount: Int

        public init(name: String, symbol: String, address: String, decimalCount: Int) {
            self.name = name
            self.symbol = symbol
            self.address = address
            self.decimalCount = decimalCount
        }
    }

    struct ID: Hashable, Sendable {
        public let chainId: String
        public let tokenAddress: String
    }
}
