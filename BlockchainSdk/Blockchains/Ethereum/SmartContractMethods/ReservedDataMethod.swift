//
//  ReservedDataMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ReservedDataMethod {
    let contractAddress: String
}

extension ReservedDataMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `getReserveData(address)` method.
    public var methodId: String { "0x35ea6a75" }
}
