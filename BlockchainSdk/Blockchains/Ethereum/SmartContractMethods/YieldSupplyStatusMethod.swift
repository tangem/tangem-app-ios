//
//  YieldSupplyStatusMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldSupplyStatusMethod {
    let contractAddress: String
}

// MARK: - SmartContractMethod

extension YieldSupplyStatusMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `yieldTokensData(address)` method.
    public var methodId: String { "0xf8e8be9c" }
}
