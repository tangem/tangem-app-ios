//
//  WithdrawAndDeactivateMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct WithdrawAndDeactivateMethod {
    let tokenContractAddress: String

    public init(tokenContractAddress: String) {
        self.tokenContractAddress = tokenContractAddress
    }
}

extension WithdrawAndDeactivateMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `withdrawAndDeactivate(address)` method.
    public var methodId: String { "0xc65e6dcf" }
    public var data: Data { defaultData() }
}
