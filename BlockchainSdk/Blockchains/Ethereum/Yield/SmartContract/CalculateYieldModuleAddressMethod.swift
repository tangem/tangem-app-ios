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

extension CalculateYieldModuleAddressMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `calculateYieldModuleAddress(address owner)` method.
    public var methodId: String { "0xf4c13c36" }
    public var data: Data { defaultData() }
}
