//
//  SendMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct SendMethod {
    let yieldTokenAddress: String
    let destination: String
    let amount: BigUInt
}

extension SendMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `send(address,address,uint256)` method.
    public var methodId: String { "0x9bd9bbc6" }
}
