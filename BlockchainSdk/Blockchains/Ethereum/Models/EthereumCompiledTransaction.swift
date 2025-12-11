//
//  EthereumCompiledTransaction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct EthereumCompiledTransaction {
    public let from: String
    public let gasLimit: BigUInt
    public let to: String
    public let data: String
    public let nonce: Int
    public let maxFeePerGas: BigUInt?
    public let maxPriorityFeePerGas: BigUInt?
    public let gasPrice: BigUInt?
    public let chainId: Int
    public let value: BigUInt?
}
