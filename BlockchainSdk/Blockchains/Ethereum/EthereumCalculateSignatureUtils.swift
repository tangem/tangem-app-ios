//
//  EthereumCalculateSignatureUtil.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct EthereumCalculateSignatureUtil {
    // It's strange but we can't use `unmarshal.v` here because WalletCore throw a error.
    // And we have to add one zero byte to the signature because
    // WalletCore has a validation on the signature count.
    // https://github.com/tangem-developments/wallet-core/blob/996bd5ab37f27e7f6e240a4ec9d0788dfb124e89/src/PublicKey.h#L35

    public init() {}

    /// Common logic for EVM blockchains. Change carefully
    public func encodeSignatureVBytes(value: Data) -> Data {
        let v = BigUInt(value) - 27
        let encodedV = v == .zero ? Data([UInt8.zero]) : v.serialize()
        return encodedV
    }

    /// Extracts the ECDSA recovery bit (yParity) from the signature `v` value.
    /// In modern typed EVM transactions (EIP-1559 / EIP-7702), `v` already equals the y-coordinate parity of the public key (0 or 1).
    /// In legacy signatures, `v` is encoded as 27 or 28 and must be normalized.
    /// Returns `nil` if the value cannot be interpreted as a valid recovery bit.
    public func extractYParity(from vData: Data) -> Int? {
        let v = Int(BigUInt(vData))

        switch v {
        case 0, 1:
            return v
        case 27, 28:
            return v - 27
        default:
            return nil
        }
    }
}
