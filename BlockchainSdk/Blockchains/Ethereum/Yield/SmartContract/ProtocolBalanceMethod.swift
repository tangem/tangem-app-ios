//
//  ProtocolBalanceMethod.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct ProtocolBalanceMethod {
    let yieldTokenAddress: String
}

extension ProtocolBalanceMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `protocolBalance(address)` method.
    public var methodId: String { "0x4bd22a1b" }
    public var data: Data { defaultData() }
}
