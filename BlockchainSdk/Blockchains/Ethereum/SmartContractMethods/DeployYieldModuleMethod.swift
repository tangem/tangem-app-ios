//
//  DeployYieldModuleMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct DeployYieldModuleMethod {
    let sourceAddress: String
    let tokenAddress: String
    let maxNetworkFee: BigUInt
}

extension DeployYieldModuleMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `deployYieldModule(address,address,uint240)` method.
    var methodId: String { "0x4b7e7f15" }
    
    var data: Data {
        let methodId = Data(hex: methodId)
        let sourceAddress = Data(hexString: sourceAddress).leadingZeroPadding(toLength: 32)
        let tokenAddress = Data(hexString: tokenAddress).leadingZeroPadding(toLength: 32)
        let maxNetworkFee = maxNetworkFee.serialize().leadingZeroPadding(toLength: 32)
        
        return methodId + sourceAddress + tokenAddress + maxNetworkFee
    }
}
