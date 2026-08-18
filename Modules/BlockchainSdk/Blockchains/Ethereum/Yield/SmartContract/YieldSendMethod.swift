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

    public init(tokenContractAddress: String, destination: String, amount: BigUInt) throws {
        self.tokenContractAddress = try SmartContractAddress(tokenContractAddress)
        self.destination = try SmartContractAddress(destination)
        self.amount = amount
    }
}

extension YieldSendMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `send(address yieldToken, address to, uint amount)` method.
    public var methodId: String { "0x0779afe6" }
    public var data: Data { defaultData() }
}
