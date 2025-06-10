//
//  Token.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct Token: Hashable, Equatable, Codable {
    public var id: String?
    public let name: String
    public let symbol: String
    public let contractAddress: String
    public let decimalCount: Int

    public init(name: String, symbol: String, contractAddress: String, decimalCount: Int, id: String? = nil) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.contractAddress = contractAddress
        self.decimalCount = decimalCount
    }

    public init(_ sdkToken: WalletData.Token, id: String? = nil) {
        self.id = id
        name = sdkToken.name
        symbol = sdkToken.symbol
        contractAddress = sdkToken.contractAddress
        decimalCount = sdkToken.decimals
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
