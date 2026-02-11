//
//  RainCryptoUtilities.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk

public enum RainCryptoUtilities {
    private static let tagLength: Int = 16

    private static var keyAttributes: CFDictionary {
        let keyAttributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]
        return keyAttributes as CFDictionary
    }

    public static func generateSecretKeyAndSessionId(publicKey: String) throws -> (secretKey: String, sessionId: String) {
        let secretKey = try CryptoUtils.generateRandomBytes(count: 32).hexString
        let sessionId = try generateSessionId(publicKey: publicKey, secretKey: secretKey)
        return (secretKey: secretKey, sessionId: sessionId)
    }

    public static func generateSessionId(publicKey: String, secretKey: String) throws(RainCryptoUtilitiesError) -> String {
        guard let secretKeyBase64Data = Data(hexString: secretKey).base64EncodedString().data(using: .utf8) else {
            throw .invalidSecretKey(secretKey)
        }

        guard let publicKeyData = Data(base64Encoded: publicKey) else {
            throw .invalidBase64EncodedPublicKey(publicKey)
        }

        guard let publicKey = SecKeyCreateWithData(publicKeyData as CFData, keyAttributes, nil) else {
            throw .failedToCreateSecKey(publicKeyData)
        }

        guard let encryptedData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionOAEPSHA1, secretKeyBase64Data as CFData, nil) else {
            throw .failedToEncryptDataWithPublicKey(secretKeyBase64Data, publicKey)
        }

        return (encryptedData as Data).base64EncodedString()
    }

    public static func encryptPin(pin: String, secretKey: String) throws -> (base64Secret: String, base64Iv: String) {
        // Format PIN into ISO 9564 Format 2 PIN block: 2[length][PIN][padding with F]
        // Example: "246784FFFFFFFFFF" for PIN "6784"
        let pinBlock = "\(Character.ISO_9564_Format_2_prefix)\(pin.count)\(pin)\(String(repeating: "F", count: 14 - pin.count))"

        guard let pinBlockData = pinBlock.data(using: .utf8) else {
            throw RainCryptoUtilitiesError.invalidSecretToEncrypt(pin)
        }

        let ivData = try CryptoUtils.generateRandomBytes(count: 16)
        let encryptedData: Data
        do {
            let nonce = try AES.GCM.Nonce(data: ivData)
            let sealedBox = try AES.GCM.seal(pinBlockData, using: SymmetricKey(data: Data(hexString: secretKey)), nonce: nonce)
            encryptedData = sealedBox.ciphertext + sealedBox.tag
        } catch {
            throw RainCryptoUtilitiesError.aesGCM(error)
        }

        return (base64Secret: encryptedData.base64EncodedString(), base64Iv: ivData.base64EncodedString())
    }

    public static func decryptPinBlock(
        encryptedBlock: String
    ) throws -> String {
        guard encryptedBlock.count >= 16 else {
            throw RainCryptoUtilitiesError
                .invalidDecryptedPinBlock(encryptedBlock)
        }

        let chars = Array(encryptedBlock)

        guard chars[0] == Character.ISO_9564_Format_2_prefix else {
            throw RainCryptoUtilitiesError
                .invalidDecryptedPinBlock(encryptedBlock)
        }

        guard let pinLength = Int(String(chars[1])) else {
            throw RainCryptoUtilitiesError
                .invalidDecryptedPinBlock(encryptedBlock)
        }

        let pinStartIndex = 2
        let pinEndIndex = pinStartIndex + pinLength
        guard pinEndIndex <= chars.count else {
            throw RainCryptoUtilitiesError
                .invalidDecryptedPinBlock(encryptedBlock)
        }

        let pin = String(chars[pinStartIndex ..< pinEndIndex])
        return pin
    }

    public static func decryptSecret(base64Secret: String, base64Iv: String, secretKey: String) throws(RainCryptoUtilitiesError) -> String {
        guard let secretData = Data(base64Encoded: base64Secret) else {
            throw .invalidBase64EncodedSecret(base64Secret)
        }

        guard let ivData = Data(base64Encoded: base64Iv) else {
            throw .invalidBase64EncodedIv(base64Iv)
        }

        let decryptedData: Data
        do {
            let nonce = try AES.GCM.Nonce(data: ivData)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: secretData.dropLast(tagLength), tag: secretData.suffix(tagLength))
            decryptedData = try AES.GCM.open(sealedBox, using: SymmetricKey(data: Data(hexString: secretKey)))
        } catch {
            throw .aesGCM(error)
        }

        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw .invalidDecryptedData(decryptedData)
        }

        return decryptedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension RainCryptoUtilities {
    enum RainCryptoUtilitiesError: Error {
        case invalidSecretKey(String)
        case invalidBase64EncodedPublicKey(String)
        case failedToCreateSecKey(Data)
        case failedToEncryptDataWithPublicKey(Data, SecKey)

        case invalidBase64EncodedSecret(String)
        case invalidBase64EncodedIv(String)
        case aesGCM(Error)
        case invalidDecryptedData(Data)
        case invalidSecretToEncrypt(String)
        case invalidDecryptedPinBlock(String)
    }
}

private extension Character {
    static let ISO_9564_Format_2_prefix: Self = "2"
}
