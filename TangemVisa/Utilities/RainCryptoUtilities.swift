//
//  RainCryptoUtilities.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

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

    public static func getRainRSAPublicKey(for apiType: VisaAPIType) throws -> String {
        try VisaConfigProvider.shared().getRainRSAPublicKey(apiType: apiType)
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
    }
}
