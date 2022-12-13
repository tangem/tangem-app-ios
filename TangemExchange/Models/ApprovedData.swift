//
//  ApprovedData.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ApprovedData {
    public let oneInchTxData: Data
    public let gasPrice: Decimal
    public let spenderAddress: String
    public let tokenAddress: String

    public init(
        oneInchTxData: Data,
        gasPrice: Decimal,
        spenderAddress: String,
        tokenAddress: String
    ) {
        self.oneInchTxData = oneInchTxData
        self.gasPrice = gasPrice
        self.spenderAddress = spenderAddress
        self.tokenAddress = tokenAddress
    }
}
