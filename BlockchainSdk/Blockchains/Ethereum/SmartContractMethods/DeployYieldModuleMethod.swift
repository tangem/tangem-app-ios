//
//  DeployYieldModuleMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct DeployYieldModuleMethod {
    let sourceAddress: String
    let tokenAddress: String
    let maxNetworkFee: BigUInt

    public init(sourceAddress: String, tokenAddress: String, maxNetworkFee: BigUInt) {
        self.sourceAddress = sourceAddress
        self.tokenAddress = tokenAddress
        self.maxNetworkFee = maxNetworkFee
    }
}

extension DeployYieldModuleMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `deployYieldModule(address owner, address yieldToken, uint240 maxNetworkFee)` method.
    public var methodId: String { "0xcbeda14c" }

    public var data: Data {
        let methodId = Data(hex: methodId)
        let sourceAddress = Data(hexString: sourceAddress).leadingZeroPadding(toLength: 32)
        let tokenAddress = Data(hexString: tokenAddress).leadingZeroPadding(toLength: 32)
        let maxNetworkFee = maxNetworkFee.serialize().leadingZeroPadding(toLength: 32)

        return methodId + sourceAddress + tokenAddress + maxNetworkFee
    }
}
