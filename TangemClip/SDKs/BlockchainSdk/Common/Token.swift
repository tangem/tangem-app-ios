//
//  Token.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Token: Hashable, Equatable, Codable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(contractAddress)
        hasher.combine(symbol)
    }
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.contractAddress.lowercased() == rhs.contractAddress.lowercased()
    }
    
    public let name: String
    public let symbol: String
    public let contractAddress: String
    public let decimalCount: Int
    
    public init(name: String? = nil, symbol: String, contractAddress: String, decimalCount: Int) {
        self.name = name ?? symbol
        self.symbol = symbol
        self.contractAddress = contractAddress
        self.decimalCount = decimalCount
    }
    
    init(_ blockhairToken: BlockchairToken) {
        self.name = blockhairToken.name
        self.symbol = blockhairToken.symbol
        self.contractAddress = blockhairToken.address
        self.decimalCount = blockhairToken.decimals
    }
}
