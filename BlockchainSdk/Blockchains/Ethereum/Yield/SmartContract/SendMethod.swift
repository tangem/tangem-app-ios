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
    let tokenContractAddress: String
    let destination: String
    let amount: BigUInt
}

extension SendMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `send(address yieldToken, address to, uint amount)` method.
    public var methodId: String { "0x0779afe6" }
    public var data: Data { defaultData() }
}
