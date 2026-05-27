//
//  EffectiveBalanceMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct EffectiveBalanceMethod {
    let tokenContractAddress: String
}

extension EffectiveBalanceMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `effectiveBalance(address yieldToken)` method.
    public var methodId: String { "0x16a398f7" }
    public var data: Data { defaultData() }
}
