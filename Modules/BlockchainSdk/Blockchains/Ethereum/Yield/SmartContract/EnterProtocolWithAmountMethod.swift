//
//  EnterProtocolWithAmountMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct EnterProtocolWithAmountMethod {
    let tokenContractAddress: String
    let amount: BigUInt

    public init(tokenContractAddress: String, amount: BigUInt) {
        self.tokenContractAddress = tokenContractAddress
        self.amount = amount
    }
}

extension EnterProtocolWithAmountMethod: SmartContractMethod {
    public var methodId: String { "0x3e44dfd2" }
    public var data: Data { defaultData() }
}
