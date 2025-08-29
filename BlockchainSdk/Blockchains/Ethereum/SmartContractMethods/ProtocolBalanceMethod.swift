//
//  ProtocolBalanceMethod 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct ProtocolBalanceMethod {
    let yieldTokenAddress: String
}

extension ProtocolBalanceMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `protocolBalance(address)` method.
    var methodId: String { "0x6f1f7f7b" }

    var data: Data {
        let methodId = Data(hex: methodId)
        let yieldTokenAddress = Data(hexString: yieldTokenAddress).leadingZeroPadding(toLength: 32)

        return methodId + yieldTokenAddress
    }
}
