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
    let tokenContractAddress: String

    public init(tokenContractAddress: String) {
        self.tokenContractAddress = tokenContractAddress
    }
}

extension EnterProtocolMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `enterProtocolByOwner(address yieldToken)` method.
    public var methodId: String { "0x79be55f7" }
    public var data: Data { defaultData() }
}
