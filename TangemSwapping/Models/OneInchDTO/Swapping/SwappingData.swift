//
//  SwappingData.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingData: Decodable {
    public let fromToken: SwappingTokenData
    public let toToken: SwappingTokenData
    public let toTokenAmount: String
    public let fromTokenAmount: String
    public let protocols: [[[ProtocolInfo]]]
    public let tx: TransactionData
}
