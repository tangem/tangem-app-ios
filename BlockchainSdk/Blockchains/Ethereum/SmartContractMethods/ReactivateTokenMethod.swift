//
//  ReactivateTokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct ReactivateTokenMethod {
    let contractAddress: String
    let maxNetworkFee: BigUInt

    public init(contractAddress: String, maxNetworkFee: BigUInt) {
        self.contractAddress = contractAddress
        self.maxNetworkFee = maxNetworkFee
    }
}

extension ReactivateTokenMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `reactivateToken(address,uint240)` method.
    public var methodId: String { "0xc478e956" }
}
