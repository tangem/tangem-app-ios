//
//  CryptoUtils.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import secp256k1

final class CryptoUtils {
    static func generateRandomBytes(count: Int) -> Data? {
        var bytes = [Byte](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        if status == errSecSuccess {
            return Data(bytes)
        } else {
            return nil
        }
    }
    
    @available(iOS 13.0, *)
    static func vefify(curve: EllipticCurve, publicKey: Data, message: Data, signature: Data) -> Bool {
        switch curve {
        case .secp256k1:
            guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY)) else { return false }
            
            defer { secp256k1_context_destroy(ctx) }
            
            let hashedMessage = message.sha256()
            var sig = secp256k1_ecdsa_signature()
            var normalized = secp256k1_ecdsa_signature()
            guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, signature.bytes) == 1 else { return false }
            
            _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
            var pubkey = secp256k1_pubkey()
            guard secp256k1_ec_pubkey_parse(ctx, &pubkey, publicKey.bytes, 65) == 1 else { return false }
            
            let result = secp256k1_ecdsa_verify(ctx, &normalized, hashedMessage.bytes, &pubkey) == 1
            return result
        case .ed25519:
            guard let edPublicKey = try? PublicKey(publicKey.bytes) else { return false }
            
            let hashedMessage = message.sha512()
            guard let result = try? edPublicKey.verify(signature: signature.bytes, message: hashedMessage.bytes) else {
                return false
            }
            
            return result
        }
    }
}
