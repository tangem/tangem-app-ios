//
//  EffectiveProtocolBalanceMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct EffectiveProtocolBalanceMethod {
    let tokenContractAddress: String
}

extension EffectiveProtocolBalanceMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `effectiveProtocolBalance(address yieldToken)` method.
    public var methodId: String { "0x5002bb7e" }
    public var data: Data { defaultData() }
}
