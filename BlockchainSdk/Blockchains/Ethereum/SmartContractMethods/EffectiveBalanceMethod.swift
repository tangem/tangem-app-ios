//
//  EffectiveBalanceMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct EffectiveBalanceMethod {
    let yieldTokenAddress: String
}

extension EffectiveBalanceMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `effectiveBalance(address)` method.
    var methodId: String { "0x6e71e2a0" }

    var data: Data {
        let methodId = Data(hex: methodId)
        let yieldTokenAddress = Data(hexString: yieldTokenAddress).leadingZeroPadding(toLength: 32)

        return methodId + yieldTokenAddress
    }
}
