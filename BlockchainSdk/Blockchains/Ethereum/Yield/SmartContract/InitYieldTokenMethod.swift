//
//  InitYieldTokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct InitYieldTokenMethod {
    let tokenContractAddress: String
    let maxNetworkFee: BigUInt

    public init(tokenContractAddress: String, maxNetworkFee: BigUInt) {
        self.tokenContractAddress = tokenContractAddress
        self.maxNetworkFee = maxNetworkFee
    }
}

extension InitYieldTokenMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `initYieldToken(address yieldToken, uint240 maxNetworkFee)` method.
    public var methodId: String { "0xebd4b81c" }
    public var data: Data { defaultData() }
}
