//
//  YieldSendMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct YieldSendMethod {
    let tokenContractAddress: SmartContractAddress
    let destination: SmartContractAddress
    let amount: BigUInt

    public init(tokenContractAddress: String, destination: SmartContractAddress, amount: BigUInt) throws {
        self.tokenContractAddress = try SmartContractAddress(tokenContractAddress)
        self.destination = destination
        self.amount = amount
    }
}

// MARK: - Convenience initializer

public extension YieldSendMethod {
    init(tokenContractAddress: String, destination: String, amount: BigUInt) throws {
        try self.init(
            tokenContractAddress: tokenContractAddress,
            destination: SmartContractAddress(destination),
            amount: amount
        )
    }
}

// MARK: - SmartContractMethod protocol conformance

extension YieldSendMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `send(address yieldToken, address to, uint amount)` method.
    public var methodId: String { "0x0779afe6" }
    public var data: Data { defaultData() }
}
