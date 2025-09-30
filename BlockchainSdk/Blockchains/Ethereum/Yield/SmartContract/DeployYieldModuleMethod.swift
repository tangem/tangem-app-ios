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
    let walletAddress: String
    let tokenContractAddress: String
    let maxNetworkFee: BigUInt

    public init(walletAddress: String, tokenContractAddress: String, maxNetworkFee: BigUInt) {
        self.walletAddress = walletAddress
        self.tokenContractAddress = tokenContractAddress
        self.maxNetworkFee = maxNetworkFee
    }
}

extension DeployYieldModuleMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `deployYieldModule(address owner, address yieldToken, uint240 maxNetworkFee)` method.
    public var methodId: String { "0xcbeda14c" }
    public var data: Data { defaultData() }
}
