//
//  Token.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct Token: Hashable, Equatable, Encodable {
    public let id: String?
    public let name: String
    public let symbol: String
    public let contractAddress: String
    public let decimalCount: Int
    public let metadata: TokenMetadata

    public init(
        name: String,
        symbol: String,
        contractAddress: String,
        decimalCount: Int,
        id: String? = nil,
        metadata: TokenMetadata = .fungibleTokenMetadata
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.contractAddress = contractAddress
        self.decimalCount = decimalCount
        self.metadata = metadata
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(contractAddress.lowercased())
    }

    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.contractAddress.lowercased() == rhs.contractAddress.lowercased()
    }
}

public extension Token {
    var decimalValue: Decimal {
        return pow(Decimal(10), decimalCount)
    }
}

public extension Token {
    init(_ sdkToken: WalletData.Token, id: String? = nil) {
        self.init(
            name: sdkToken.name,
            symbol: sdkToken.symbol,
            contractAddress: sdkToken.contractAddress,
            decimalCount: sdkToken.decimals,
            id: id
        )
    }
}

extension Token: Decodable {
    /// - Note: Custom `Decodable` implementation is used to perform migration for already stored tokens without `metadata`.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = try container.decode(String.self, forKey: .name)
        let symbol = try container.decode(String.self, forKey: .symbol)
        let contractAddress = try container.decode(String.self, forKey: .contractAddress)
        let decimalCount = try container.decode(Int.self, forKey: .decimalCount)
        let id = try? container.decodeIfPresent(String.self, forKey: .id)
        let metadata = try? container.decodeIfPresent(TokenMetadata.self, forKey: .metadata)

        self.init(
            name: name,
            symbol: symbol,
            contractAddress: contractAddress,
            decimalCount: decimalCount,
            id: id,
            metadata: metadata ?? .fungibleTokenMetadata
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case symbol
        case contractAddress
        case decimalCount
        case metadata
    }
}
