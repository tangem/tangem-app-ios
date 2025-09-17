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
    let yieldModuleAddress: String
    let maxNetworkFee: BigUInt

    public init(yieldModuleAddress: String, maxNetworkFee: BigUInt) {
        self.yieldModuleAddress = yieldModuleAddress
        self.maxNetworkFee = maxNetworkFee
    }
}

extension InitYieldTokenMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `initYieldToken(address,uint240)` method.
    public var methodId: String { "0xebd4b81c" }
}
