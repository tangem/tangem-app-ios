//
//  ExchangeApprovedDataModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeApprovedDataModel {
    public let data: Data
    public let gasPrice: String
    public let tokenAddress: String
    public let value: String

    public init(data: Data, gasPrice: String, tokenAddress: String, value: String) {
        self.data = data
        self.gasPrice = gasPrice
        self.tokenAddress = tokenAddress
        self.value = value
    }

    public init(approveTxData: ApprovedTransactionData) {
        data = Data(hexString: approveTxData.data)
        gasPrice = approveTxData.gasPrice
        tokenAddress = approveTxData.to
        value = approveTxData.value
    }
}
