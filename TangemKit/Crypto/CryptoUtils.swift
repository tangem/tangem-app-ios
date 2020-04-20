////
////  CryptoUtils.swift
////  TangemKit
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2019 Smart Cash AG. All rights reserved.
////
//
//import Foundation
//import secp256k1
//
//struct CryptoKeyPair {
//    let privateKey: Data
//    let publicKey: Data
//}
//
//class CryptoUtils {    
//    static func getRandomBytes(count: Int) -> [UInt8]? {
//        var bytes = [UInt8](repeating: 0, count: count)
//        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
//        
//        if status == errSecSuccess {
//            return bytes
//        } else {
//            return nil
//        }
//    }
//    
//    static func getCryproKeyPair() -> CryptoKeyPair? {
//        var context = secp256k1_context_create([SECP256K1_FLAGS.SECP256K1_CONTEXT_SIGN])!
//        defer {
//             secp256k1_context_destroy(&context)
//        }
//        guard let privateKey = getRandomBytes(count: 32) else {
//            return nil
//        }
//        
//        let privateKeyData = Data(privateKey)
//        guard let publicKeyData = privateKeyToPublicKey(context, privateKey: privateKeyData) else {
//            return nil
//        }
//        
//        return CryptoKeyPair(privateKey: privateKeyData, publicKey: publicKeyData)
//    }
//    
//    static func verifyPrivateKey(_ context: secp256k1_context, privateKey: Data) -> Bool {
//        if (privateKey.count != 32) {return false}
//
//        let res = secp256k1_ec_seckey_verify(context, Array(privateKey))
//        return res
//    }
//    
//    static func privateKeyToPublicKey(_ context: secp256k1_context, privateKey: Data) -> Data? {
//        if (privateKey.count != 32) {return nil}
//        var publicKey = secp256k1_pubkey()
//        let res = secp256k1_ec_pubkey_create(context, &publicKey, Array(privateKey))
//        guard res else {
//            return nil
//        }
//        
//        var pubLength: UInt = 65
//        var pubKeyUncompressed = Array(repeating: 0, count: Int(pubLength)) as [UInt8]
//        let serializeResult = secp256k1_ec_pubkey_serialize(context, &pubKeyUncompressed, &pubLength, publicKey, SECP256K1_FLAGS.SECP256K1_EC_UNCOMPRESSED)
//        guard serializeResult else {
//            return nil
//        }
//        
//        return Data(pubKeyUncompressed)
//    }
//    
//    static func sign(_ data: Data, with key: Data) -> Data? {
//        var context = secp256k1_context_create(SECP256K1_FLAGS.SECP256K1_CONTEXT_SIGN)!
//        defer {
//            secp256k1_context_destroy(&context)
//        }
//        var signature = secp256k1_ecdsa_signature()
//        let result = secp256k1_ecdsa_sign(context, &signature, Array(data), Array(key), nil, nil)
//        guard result else {
//            return nil
//        }
//        
//        return Data(signature.data)
//    }
//    
//    static func verifySignature(signature: Data, data: Data, publicKey: Data) -> Bool {               
//               var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
//               var sig = secp256k1_ecdsa_signature()
//               var normalized = secp256k1_ecdsa_signature()
//               let sigLoaded = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, signature.bytes)
//               let sigNormalized = secp256k1_ecdsa_signature_normalize(vrfy, &normalized, sig)
//               var pubkey = secp256k1_pubkey()
//               let pubKeyLoaded = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKey.bytes, 65)
//               let result = secp256k1_ecdsa_verify(vrfy, normalized, data.bytes, pubkey)
//               secp256k1_context_destroy(&vrfy)
//               return result
//           }
//}
