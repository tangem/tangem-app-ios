//
//  InitYieldTokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct InitYieldTokenMethod {
    let yieldTokenAddress: String
    let maxNetworkFee: BigUInt
}

extension InitYieldTokenMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `initYieldToken(address,uint240)` method.
    var methodId: String { "0x3b7e4f2f" }
    
    var data: Data {
        let methodId = Data(hex: methodId)
        let yieldTokenAddress = Data(hexString: yieldTokenAddress).leadingZeroPadding(toLength: 32)
        let maxNetworkFee = maxNetworkFee.serialize().leadingZeroPadding(toLength: 32)
        
        return methodId + yieldTokenAddress + maxNetworkFee
    }
}
