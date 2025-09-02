//
//  YieldModuleMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldModuleMethod {
    let address: String
}

// MARK: - SmartContractMethod

extension YieldModuleMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `yieldModules(address)` method.
    public var methodId: String { "0x36571e2c" }
}
