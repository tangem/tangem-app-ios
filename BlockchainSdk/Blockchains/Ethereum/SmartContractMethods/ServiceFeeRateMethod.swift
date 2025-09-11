//
//  ServiceFeeRateMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ServiceFeeRateMethod {
    public init() {}
}

// MARK: - SmartContractMethod

extension ServiceFeeRateMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `serviceFeeRate()` method.
    public var methodId: String { "0x61d1bc94" }
}
