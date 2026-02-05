//
//  EthereumStakeKitTransaction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct EthereumCompiledTransactionData: Decodable, Hashable {
    public let from: String
    public let gasLimit: String
    public let to: String
    public let data: String
    public let nonce: Int
    public let maxFeePerGas: String?
    public let maxPriorityFeePerGas: String?
    public let gasPrice: String?
    public let chainId: Int
    public let value: String?

    public init(
        from: String,
        gasLimit: String,
        to: String,
        data: String,
        nonce: Int,
        maxFeePerGas: String?,
        maxPriorityFeePerGas: String?,
        gasPrice: String?,
        chainId: Int,
        value: String?
    ) {
        self.from = from
        self.gasLimit = gasLimit
        self.to = to
        self.data = data
        self.nonce = nonce
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
        self.gasPrice = gasPrice
        self.chainId = chainId
        self.value = value
    }
}
