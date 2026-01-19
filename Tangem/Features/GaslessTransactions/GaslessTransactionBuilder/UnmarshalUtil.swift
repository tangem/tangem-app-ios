//
//  UnmarshalUtil.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import BigInt

enum UnmarshalUtil {
    struct UnmarshalledSignature {
        let r: Data
        let s: Data
        let yParity: Int
        let extended: Data
    }

    enum UnmarshalUtilError: Error {
        case incorrectSignatureLength
        case failedToExtractYParity
    }

    static func unmarshalSignature(signatureInfo: SignatureInfo, publicKey: Data) throws -> UnmarshalledSignature {
        guard signatureInfo.signature.count == 64 else {
            throw UnmarshalUtilError.incorrectSignatureLength
        }

        let decompressedPublicKey = try Secp256k1Key(with: publicKey).decompress()
        let signature = try Secp256k1Signature(with: signatureInfo.signature)
        let unmarshaled = try signature.unmarshal(with: decompressedPublicKey, hash: signatureInfo.hash)
        let yParity = EthereumCalculateSignatureUtil().extractYParity(from: unmarshaled.v)

        return UnmarshalledSignature(r: unmarshaled.r, s: unmarshaled.s, yParity: yParity, extended: unmarshaled.data)
    }
}
