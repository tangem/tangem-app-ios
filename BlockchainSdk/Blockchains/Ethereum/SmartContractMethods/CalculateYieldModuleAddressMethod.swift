//
//  CalculateYieldModuleAddressMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct CalculateYieldModuleAddressMethod {
    let sourceAddress: String

    public init(sourceAddress: String) {
        self.sourceAddress = sourceAddress
    }
}

extension CalculateYieldModuleAddressMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `calculateYieldModuleAddress(address)` method.
    public var methodId: String { "0xebd6d0a4" }
}
