//
//  YieldTokenDataMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldTokenDataMethod {
    let yieldTokenAddress: String
}

// MARK: - SmartContractMethod

extension YieldTokenDataMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `yieldTokensData(address)` method.
    public var methodId: String { "0x8f2b1f2d" }
}
