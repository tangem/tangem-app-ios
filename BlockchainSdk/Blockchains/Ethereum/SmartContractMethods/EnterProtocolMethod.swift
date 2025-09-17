//
//  EnterProtocolMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct EnterProtocolMethod {
    let yieldModuleAddress: String

    public init(yieldModuleAddress: String) {
        self.yieldModuleAddress = yieldModuleAddress
    }
}

extension EnterProtocolMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `enterProtocolByOwner(address)` method.
    public var methodId: String { "0x79be55f7" }
}
