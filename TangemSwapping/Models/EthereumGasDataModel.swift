//
//  EthereumGasDataModel.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct EthereumGasDataModel {
    public let blockchain: SwappingBlockchain
    public let gasPrice: Int
    public let gasLimit: Int
    public let fee: Decimal

    public init(blockchain: SwappingBlockchain, gasPrice: Int, gasLimit: Int, fee: Decimal) {
        self.blockchain = blockchain
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.fee = fee
    }
}
