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
    let networkFee: BigUInt

    public init(yieldTokenAddress: String, networkFee: BigUInt) {
        self.yieldTokenAddress = yieldTokenAddress
        self.networkFee = networkFee
    }
}

extension EnterProtocolMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `enterProtocol(address,uint256)` method.
    public var methodId: String { "0x1c0a33d0" }

    public var data: Data {
        let methodId = Data(hex: methodId)
        let yieldTokenAddress = Data(hexString: yieldTokenAddress).leadingZeroPadding(toLength: 32)
        let networkFee = networkFee.serialize().leadingZeroPadding(toLength: 32)

        return methodId + yieldTokenAddress + networkFee
    }
}
