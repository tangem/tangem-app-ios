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
    // It's strange but we can't use `unmarshal.v` here because WalletCore throw a error.
    // And we have to add one zero byte to the signature because
    // WalletCore has a validation on the signature count.
    // https://github.com/tangem-developments/wallet-core/blob/996bd5ab37f27e7f6e240a4ec9d0788dfb124e89/src/PublicKey.h#L35

    /// Common logic for EVM blockchains. Change carefully
    func encodeSignatureVBytes(value: Data) -> Data {
        let v = BigUInt(value) - 27
        let encodedV = v == .zero ? Data([UInt8.zero]) : v.serialize()
        return encodedV
    }
}
