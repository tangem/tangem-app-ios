//
//  QuoteData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct QuoteData: Decodable {
    public let fromToken: TokenInfo
    public let toToken: TokenInfo
    public let toTokenAmount: String
    public let fromTokenAmount: String
    public let protocols: [[[ProtocolInfo]]]
    public let estimatedGas: Int
}

public struct TokenInfo: Decodable {
    public let symbol: String
    public let name: String
    public let address: String
    public let decimals: Int
    public let logoURI: String
}

public struct ProtocolInfo: Decodable {
    public let name: String
    public let part: Int
    public let fromTokenAddress: String
    public let toTokenAddress: String
}
