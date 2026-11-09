//
//  MCPToken.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.URL
public import struct TangemAssets.ImageType

// [REDACTED_TODO_COMMENT]

public struct MCPToken: Equatable, Sendable {
    public let displayName: String
    public let symbol: String
    public let network: Self.Blockchain
    public let kind: Self.Kind

    public init(displayName: String, symbol: String, network: Self.Blockchain, kind: Self.Kind) {
        self.displayName = displayName
        self.symbol = symbol
        self.network = network
        self.kind = kind
    }
}

public extension MCPToken {
    struct Blockchain: Equatable, Sendable {
        public let iconAsset: ImageType

        public init(iconAsset: ImageType) {
            self.iconAsset = iconAsset
        }
    }

    enum Kind: Equatable, Sendable {
        /// The network's own coin (ETH on Ethereum, BTC on Bitcoin)
        case nativeCoin

        /// A token Tangem knows, identified by a backend id, with a logo at `iconURL`.
        case token(iconURL: URL)

        /// A token Tangem doesn't know — no backend id and no logo — added by its contract address.
        case customToken
    }
}
