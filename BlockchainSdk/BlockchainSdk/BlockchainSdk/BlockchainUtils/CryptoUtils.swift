//
//  CryptoUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import secp256k1

class CryptoUtils {
    public static func serializeToDer(secp256k1Signature: Data) -> Data? {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_NONE)) else { return nil }
        
        defer { secp256k1_context_destroy(ctx) }
        
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, secp256k1Signature.bytes) == 1 else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
        var length: Int = 128
        var der = [UInt8].init(repeating: UInt8(0x0), count: Int(length))
        guard secp256k1_ecdsa_signature_serialize_der(ctx, &der, &length, &normalized) == 1  else { return nil }
        
        return Data(der[0..<Int(length)])
    }
}
