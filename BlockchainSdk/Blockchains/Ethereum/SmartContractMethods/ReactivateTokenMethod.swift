//
//  ReactivateTokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ReactivateTokenMethod {
    let contractAddress: String

    public init(contractAddress: String) {
        self.contractAddress = contractAddress
    }
}

extension ReactivateTokenMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `reactivateToken(address)` method.
    public var methodId: String { "0x0d31916f" }
}
