//
//  PINCodeProcessor.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import CryptoSwift

protocol PINCodeProcessor {
    func processSelectedPINCode(_ pinCode: String) async throws -> ProcessedPIN
}

struct ProcessedPIN {
    let sessionKey: String
    let iv: String
    let encryptedPIN: String
}

class PaymentologyPINCodeProcessor {
    private let rsaPublicKey: String
    private let sessionKey = SymmetricKey(size: .bits256)
    private let rsaKeySize = 2048
    private let ivLength = 16

    init(rsaPublicKey: String) {
        self.rsaPublicKey = rsaPublicKey
    }

    private func makePublicKey() throws (PaymentologyError) -> SecKey {
        guard let der = Data(base64Encoded: rsaPublicKey, options: .ignoreUnknownCharacters) else {
            throw .invalidRSAKeyFormat
        }

        let attributes: [String: Any] = [
            String(kSecAttrKeyType): kSecAttrKeyTypeRSA,
            String(kSecAttrKeyClass): kSecAttrKeyClassPublic,
            String(kSecAttrKeySizeInBits): rsaKeySize,
        ]

        guard let publicKey = SecKeyCreateWithData(der as CFData, attributes as CFDictionary, nil) else {
            throw .failedToCreateRSAKey
        }

        return publicKey
    }

    private func makeSessionId() throws (PaymentologyError) -> String {
        let publicKey = try makePublicKey()

        let base64SessionKey = sessionKey.base64Representation

        guard let base64SessionKeyData = base64SessionKey.data(using: .utf8) else {
            throw .invalidSessionKeyFormat
        }

        guard let sessionIdData = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionOAEPSHA1,
            base64SessionKeyData as CFData,
            nil
        ) else {
            throw .failedToCreateSessionIdData
        }

        return (sessionIdData as Data).base64EncodedString()
    }

    private func generateIV() -> Data {
        var randomBytes = [UInt8](repeating: 0, count: ivLength)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return Data(randomBytes)
    }

    private func encrypt(message: String, ivData: Data) throws -> String {
        guard let messageData = message.data(using: .utf8) else {
            throw PaymentologyError.invalidMessageFormat
        }

        let aes = try AES(
            key: sessionKey.bytes,
            blockMode: GCM(iv: ivData.bytes, mode: .combined),
            padding: .noPadding
        )

        let encryptedMessage = try aes.encrypt(messageData.bytes)
        return Data(encryptedMessage).base64EncodedString()
    }
}

extension PaymentologyPINCodeProcessor: PINCodeProcessor {
    func processSelectedPINCode(_ pinCode: String) async throws -> ProcessedPIN {
        let sessionId = try makeSessionId()
        let ivData = generateIV()
        let ivBase64 = ivData.base64EncodedString()

        // ISO Format 2 Pin block CLPPPPffffffffFF
        let pinBlock = "2\(pinCode.count)\(pinCode)\(String(repeating: "f", count: 12 - pinCode.count))FF"
        let encryptedPinBase64 = try encrypt(message: pinBlock, ivData: ivData)
        return .init(
            sessionKey: sessionId,
            iv: ivBase64,
            encryptedPIN: encryptedPinBase64
        )
    }
}

extension PaymentologyPINCodeProcessor {
    enum PaymentologyError: String, LocalizedError {
        case invalidSessionKeyFormat
        case invalidRSAKeyFormat
        case failedToCreateRSAKey
        case failedToCreateSessionIdData
        case failedToCreateSessionId
        case invalidMessageFormat
    }
}

private extension SymmetricKey {
    var bytes: [UInt8] {
        withUnsafeBytes {
            return Array($0)
        }
    }

    var data: Data {
        Data(bytes)
    }

    var base64Representation: String {
        data.base64EncodedString()
    }
}
