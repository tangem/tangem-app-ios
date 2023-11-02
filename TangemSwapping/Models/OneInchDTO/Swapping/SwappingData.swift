//
//  SwappingData.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingData: Decodable {
    public let toAmount: String
    public let tx: TransactionData

    public let fromToken: SwappingTokenData?
    public let toToken: SwappingTokenData?
    public let protocols: [[[ProtocolInfo]]]?
}
