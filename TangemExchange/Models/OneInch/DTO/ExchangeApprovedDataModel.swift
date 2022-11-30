//
//  ExchangeApprovedDataModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeApprovedDataModel {
    let data: Data
    let gasPrice: String
    let tokenAddress: String
    let value: String

    init(data: Data, gasPrice: String, tokenAddress: String, value: String) {
        self.data = data
        self.gasPrice = gasPrice
        self.tokenAddress = tokenAddress
        self.value = value
    }

    init(approveTxData: ApprovedTransactionData) {
        data = Data(hexString: approveTxData.data)
        gasPrice = approveTxData.gasPrice
        tokenAddress = approveTxData.to
        value = approveTxData.value
    }
}
