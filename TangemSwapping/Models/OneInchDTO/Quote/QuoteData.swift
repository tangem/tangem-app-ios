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
