//
//  SendMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct SendMethod {
    let yieldTokenAddress: String
    let destination: String
    let amount: BigUInt
}

extension SendMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `send(address,address,uint256)` method.
    var methodId: String { "0x9bd9bbc6" }
    
    var data: Data {
        let methodId = Data(hex: methodId)
        let yieldTokenAddress = Data(hexString: yieldTokenAddress).leadingZeroPadding(toLength: 32)
        let destination = Data(hexString: destination).leadingZeroPadding(toLength: 32)
        let networkFee = amount.serialize().leadingZeroPadding(toLength: 32)
        
        return methodId + yieldTokenAddress + networkFee
    }
}
