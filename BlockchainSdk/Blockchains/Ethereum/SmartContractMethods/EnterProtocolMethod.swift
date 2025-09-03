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
    let yieldTokenAddress: String

    public init(yieldTokenAddress: String) {
        self.yieldTokenAddress = yieldTokenAddress
    }
}

extension EnterProtocolMethod: YieldSmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `enterProtocolByOwner(address)` method.
    public var methodId: String { "0x79be55f7" }

//    public var data: Data {
//        let methodId = Data(hex: methodId)
//        let yieldTokenAddress = Data(hexString: yieldTokenAddress).leadingZeroPadding(toLength: 32)
//        let networkFee = networkFee.serialize().leadingZeroPadding(toLength: 32)
//
//        return methodId + yieldTokenAddress + networkFee
//    }
}
