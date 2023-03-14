//
//  EthereumGasDataModel.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct EthereumGasDataModel {
    public let blockchain: ExchangeBlockchain
    public let gasPrice: Int
    public let gasLimit: Int
    public let fee: Decimal

    public init(blockchain: ExchangeBlockchain, gasPrice: Int, gasLimit: Int, fee: Decimal = 0) {
        self.blockchain = blockchain
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.fee = fee
    }
}
