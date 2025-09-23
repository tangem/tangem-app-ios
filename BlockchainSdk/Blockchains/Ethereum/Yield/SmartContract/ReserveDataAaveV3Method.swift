//
//  ReserveDataAaveV3Method.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ReserveDataAaveV3Method {
    let contractAddress: String
}

extension ReserveDataAaveV3Method: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `getReserveData(address)` method.
    public var methodId: String { "0x35ea6a75" }
    public var data: Data { defaultData() }
}
