//
//  YieldModuleMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldModuleMethod {
    let walletAddress: String
}

// MARK: - SmartContractMethod

extension YieldModuleMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `yieldModules(address owner)` method.
    public var methodId: String { "0x36571e2c" }
    public var data: Data { defaultData() }
}
