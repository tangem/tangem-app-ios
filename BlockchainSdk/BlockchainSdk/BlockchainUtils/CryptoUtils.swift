//
//  CryptoUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import web3swift
import secp256k1

class CryptoUtils {
    public static func serializeToDer(secp256k1Signature: Data) -> Data? {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_NONE)) else { return nil }
        
        defer { secp256k1_context_destroy(ctx) }
        
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, Array(secp256k1Signature)) == 1 else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
        var length: Int = 128
        var der = [UInt8].init(repeating: UInt8(0x0), count: Int(length))
        guard secp256k1_ecdsa_signature_serialize_der(ctx, &der, &length, &normalized) == 1  else { return nil }
        
        return Data(der[0..<Int(length)])
    }
    
    public static func unmarshal(secp256k1Signature: Data, hash: Data, publicKey: Data) -> SECP256K1.UnmarshaledSignature? {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY)) else { return nil }
        
        defer { secp256k1_context_destroy(ctx) }
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, Array(secp256k1Signature)) == 1 else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, Array(publicKey), 65) == 1 else { return nil }
        guard secp256k1_ecdsa_verify(ctx, &normalized, Array(hash), &pubkey) == 1 else { return nil }
       
        var serialized = [UInt8].init(repeating: UInt8(0x0), count: 64)
        secp256k1_ecdsa_signature_serialize_compact(ctx, &serialized, &normalized)
        
        var recoveredSignature: Data? = nil
        for v in 27..<31 {
            let testV = UInt8(v)
            let testSign = Data(serialized + [testV])
      
            if let recoveredKey = SECP256K1.recoverPublicKey(hash: hash, signature: testSign, compressed: false),
                recoveredKey == publicKey {
                recoveredSignature = testSign
            }
        }
        
        if recoveredSignature == nil {
            return nil
        }
        
        let unmarshalledSignature = SECP256K1.unmarshalSignature(signatureData: recoveredSignature!)
        return unmarshalledSignature
    }
    
    public static func convertKeyToCompressed(_ walletPublicKey: Data) -> Data? {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_NONE)) else { return nil }
        
        defer { secp256k1_context_destroy(ctx) }
        
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, Array(walletPublicKey), 65) == 1 else { return nil }
        
        var pubLength = 33
        var pubKeyCompressed = Array(repeating: UInt8(0), count: Int(pubLength))
        secp256k1_ec_pubkey_serialize(ctx, &pubKeyCompressed, &pubLength, &pubkey, UInt32(SECP256K1_EC_COMPRESSED))
        
        return Data(pubKeyCompressed)
        
    }
    
    public static func normalizeVerify(secp256k1Signature: Data, hash: Data, publicKey: Data) -> Data? {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY)) else { return nil }
        
        defer { secp256k1_context_destroy(ctx) }
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, Array(secp256k1Signature)) == 1 else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
        var pubkey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_parse(ctx, &pubkey, Array(publicKey), 65) == 1 else { return nil }
        guard secp256k1_ecdsa_verify(ctx, &normalized, Array(hash), &pubkey) == 1 else { return nil }
       
        var serialized = [UInt8].init(repeating: UInt8(0x0), count: 64)
        secp256k1_ecdsa_signature_serialize_compact(ctx, &serialized, &normalized)

        return Data(serialized)
    }
}
