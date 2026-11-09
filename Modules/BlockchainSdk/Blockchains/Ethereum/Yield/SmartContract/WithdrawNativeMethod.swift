//
//  WithdrawNativeMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct WithdrawNativeMethod {
    let amount: BigUInt

    public init(amount: BigUInt) {
        self.amount = amount
    }
}

extension WithdrawNativeMethod: SmartContractMethod {
    public var methodId: String { "0x84276d81" }
    public var data: Data { defaultData() }
}
