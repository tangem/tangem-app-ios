//
//  YieldTokenDataMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldTokenDataMethod {
    let contractAddress: String
}

// MARK: - SmartContractMethod

extension YieldTokenDataMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `yieldTokensData(address)` method.
    public var methodId: String { "0xf8e8be9c" }
    public var data: Data { defaultData() }
}
