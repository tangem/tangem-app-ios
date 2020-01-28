//
//  CryptoUtils.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import secp256k1

public final class CryptoUtils {
    
    /**
     * Generates array of random bytes.
     * It is used, among other things, to generate helper private keys
     * (not the one for the blockchains, that one is generated on the card and does not leave the card).
     *
     * - Parameter count: length of the array that is to be generated.
     */
    public static func generateRandomBytes(count: Int) -> Data? {
        var bytes = [Byte](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        if status == errSecSuccess {
            return Data(bytes)
        } else {
            return nil
        }
    }
    
    /**
     * Helper function to verify that the data was signed with a private key that corresponds
     * to the provided public key.
     *  - Parameter curve: Elliptic curve used
     *  - Parameter publicKey: Corresponding to the private key that was used to sing a message
     *  - Parameter message: The data that was signed
     *  - Parameter signature: Signed data
     */
    public static func vefify(curve: EllipticCurve, publicKey: Data, message: Data, signature: Data) -> Bool? {
        switch curve {
        case .secp256k1:
            guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY)) else { return nil }
            
            defer { secp256k1_context_destroy(ctx) }
            
            let hashedMessage = message.getSha256()
            var sig = secp256k1_ecdsa_signature()
            var normalized = secp256k1_ecdsa_signature()
            guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, signature.toBytes) == 1 else { return nil }
            
            _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, &sig)
            var pubkey = secp256k1_pubkey()
            guard secp256k1_ec_pubkey_parse(ctx, &pubkey, publicKey.toBytes, 65) == 1 else { return nil }
            
            let result = secp256k1_ecdsa_verify(ctx, &normalized, hashedMessage.toBytes, &pubkey) == 1
            return result
        case .ed25519:
            guard let edPublicKey = try? PublicKey(publicKey.toBytes) else { return nil }
            
            let hashedMessage = message.getSha512()
            guard let result = try? edPublicKey.verify(signature: signature.toBytes, message: hashedMessage.toBytes) else {
                return nil
            }
            
            return result
        }
    }
    
    /**
     * Extension function to sign a byte array with the `Secp256k1` elliptic curve cryptography.
     *
     * - Parameter key: Key to sign data
     * - Parameter data: Data to sign
     *
     * - Returns: Signed data
     */
    public static func signSecp256k1(_ data: Data, with key: Data) -> Data? {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN)) else { return nil }
        
        defer { secp256k1_context_destroy(ctx) }
        
        var signature = secp256k1_ecdsa_signature()
        let result = secp256k1_ecdsa_sign(ctx, &signature, Array(data.getSha256()), Array(key), nil, nil)
        guard result == 1 else {
            return nil
        }
        
        var signatureData = [Byte](repeating: 0, count: 64)
        _ = secp256k1_ecdsa_signature_serialize_compact(ctx, &signatureData, &signature)
        
        return Data(signatureData)
    }
    
    /// Generate private/public keypair with secp256k1.
    /// - Returns: `KeyPair` with  32-bytes length `private key` and  65-bytes length uncompressed `public key`
    public static func generateKeyPair() -> KeyPair? {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY)) else { return nil }
              
        defer { secp256k1_context_destroy(ctx) }
        
        guard let privateKey = generateRandomBytes(count: 32)?.toBytes else { return nil }
        
        guard secp256k1_ec_seckey_verify(ctx, privateKey) == 1 else { return nil }
        
        var publicKeySecp = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_create(ctx, &publicKeySecp, privateKey) == 1 else { return nil }

        var publicKeyLength: Int = 65
        var publicKeyUncompressed = Array(repeating: Byte(0), count: publicKeyLength)
        secp256k1_ec_pubkey_serialize(ctx, &publicKeyUncompressed, &publicKeyLength, &publicKeySecp, UInt32(SECP256K1_EC_UNCOMPRESSED))
        return KeyPair(privateKey: Data(privateKey), publicKey: Data(publicKeyUncompressed))
    }
}
