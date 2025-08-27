//
//  ExitProtocolMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct ExitProtocolMethod {
    let yieldTokenAddress: String
    let networkFee: BigUInt
}

extension ExitProtocolMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `enterProtocol(address,uint256)` method.
    var methodId: String { "0x1c0a33d0" }
    
    var data: Data {
        let methodId = Data(hex: methodId)
        let yieldTokenAddress = Data(hexString: yieldTokenAddress).leadingZeroPadding(toLength: 32)
        let networkFee = networkFee.serialize().leadingZeroPadding(toLength: 32)
        
        return methodId + yieldTokenAddress + networkFee
    }
}
