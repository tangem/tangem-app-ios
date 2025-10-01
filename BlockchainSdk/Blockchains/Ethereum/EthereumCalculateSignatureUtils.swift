//
//  EthereumCalculateSignatureUtil.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct EthereumCalculateSignatureUtil {
    /// Common logic for EVM blockchains. Change carefully
    func encodeSignatureVBytes(value: Data) -> Data {
        let v = BigUInt(value) - 27
        let encodedV = v == .zero ? Data([UInt8.zero]) : v.serialize()
        return encodedV
    }
}
