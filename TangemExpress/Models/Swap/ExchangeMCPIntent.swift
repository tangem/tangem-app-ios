//
//  ExchangeMCPIntent.swift
//  TangemExpress
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Decimal

/// A swap an AI agent proposed through MCP, fetched by the id a `tangem://intent?...` link carries.
public struct ExchangeMCPIntent: Hashable, Sendable {
    public let intentID: String
    public let providerID: ExpressProvider.Id
    public let rateType: ExpressProviderRateType
    public let from: Self.Asset
    public let to: Self.Asset
    public let specifiedAmount: Self.SpecifiedAmount
    public let walletID: String
    public let agentID: String
}

public extension ExchangeMCPIntent {
    struct Asset: Hashable, Sendable {
        public let currency: ExpressCurrency
        public let decimals: Int
    }

    enum SpecifiedAmount: Hashable, Sendable {
        case from(Decimal)
        case to(Decimal)
    }
}
