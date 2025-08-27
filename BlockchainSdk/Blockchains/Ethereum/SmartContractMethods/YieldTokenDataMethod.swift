//
//  YieldTokenDataMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct YieldTokenDataMethod {
    let address: String
}

// MARK: - SmartContractMethod

extension YieldTokenDataMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `yieldTokensData(address)` method.
    public var methodId: String { "0x8f2b1f2d" }

    public var data: Data {
        let methodId = Data(hex: methodId)
        let address = Data(hexString: address).leadingZeroPadding(toLength: 32)

        return methodId + address
    }
}
