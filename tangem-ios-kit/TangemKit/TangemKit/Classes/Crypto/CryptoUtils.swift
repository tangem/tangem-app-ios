//
//  CryptoUtils.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import secp256k1

class CryptoUtils {    
    static func getRandomBytes(count: Int) -> [UInt8]? {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        if status == errSecSuccess {
            return bytes
        } else {
            return nil
        }
    }
    
    static func getCryproKeyPair() -> (privateKey: Data, publicKey: Data)? {
        guard let privateKey = getRandomBytes(count: 32),
            verifyPrivateKey(privateKey: Data(privateKey)) else {
            return nil
        }
        let privateKeyData = Data(privateKey)
        
        guard let publicKeyData = privateKeyToPublicKey(privateKey: privateKeyData) else {
            return nil
        }
        
        return (privateKeyData, publicKeyData)
    }
    
    static func verifyPrivateKey(privateKey: Data) -> Bool {
        if (privateKey.count != 32) {return false}
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY))!
        
        let result = privateKey.withUnsafeBytes { (privateKeyRBPointer) -> Int32? in
            if let privateKeyRPointer = privateKeyRBPointer.baseAddress, privateKeyRBPointer.count > 0 {
                let privateKeyPointer = privateKeyRPointer.assumingMemoryBound(to: UInt8.self)
                let res = secp256k1_ec_seckey_verify(context, privateKeyPointer)
                return res
            } else {
                return nil
            }
        }
        guard let res = result, res == 1 else {
            return false
        }
        return true
    }
    
    static func privateKeyToPublicKey(privateKey: Data) -> Data? {
        if (privateKey.count != 32) {return nil}
        var publicKey = secp256k1_pubkey()
        let context = secp256k1_context_create(SECP256K1_FLAGS.SECP256K1_CONTEXT_NONE)!
        let res = secp256k1_ec_pubkey_create(context, &publicKey, Array(privateKey))

        guard res else {
            return nil
        }
        
        return Data(publicKey.data)
    }
    
    static func sign(_ data: Data, with key: Data) -> Data? {
        let context = secp256k1_context_create(SECP256K1_FLAGS.SECP256K1_CONTEXT_SIGN)!
        var signature = secp256k1_ecdsa_signature()
        let result = secp256k1_ecdsa_sign(context, &signature, Array(data), Array(data), nil, nil)
        guard result else {
            return nil
        }
        
        return Data(signature.data)
    }
}
