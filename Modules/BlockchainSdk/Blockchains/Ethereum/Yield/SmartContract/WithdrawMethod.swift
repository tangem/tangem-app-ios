//
//  WithdrawMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct WithdrawMethod {
    let tokenContractAddress: String
    let amount: BigUInt

    public init(tokenContractAddress: String, amount: BigUInt) {
        self.tokenContractAddress = tokenContractAddress
        self.amount = amount
    }
}

extension WithdrawMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `withdraw(address,uint256)` method.
    public var methodId: String { "0xf3fef3a3" }
    public var data: Data { defaultData() }
}
