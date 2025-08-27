//
//  ServiceFeeRateMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ServiceFeeRateMethod {}

// MARK: - SmartContractMethod

extension ServiceFeeRateMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `serviceFeeRate()` method.
    public var methodId: String { "0x1e5b6c6f" }

    public var data: Data {
        // No inputs, so just the methodId
        return Data(hex: methodId)
    }
}
