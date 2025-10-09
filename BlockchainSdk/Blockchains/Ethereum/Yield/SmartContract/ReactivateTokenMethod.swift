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
    let tokenContractAddress: String
    let maxNetworkFee: BigUInt

    public init(tokenContractAddress: String, maxNetworkFee: BigUInt) {
        self.tokenContractAddress = tokenContractAddress
        self.maxNetworkFee = maxNetworkFee
    }
}

extension ReactivateTokenMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `reactivateToken(address yieldToken, uint240 maxNetworkFee)` method.
    public var methodId: String { "0xc478e956" }
    public var data: Data { defaultData() }
}
