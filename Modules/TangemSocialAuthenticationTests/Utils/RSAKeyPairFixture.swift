//
//  RSAKeyPairFixture.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import Security
import Testing
import TangemFoundation
@testable import TangemSocialAuthentication

enum RSAKeyPairFixture {
    static let keySizeInBits = 2048

    static let maximumOAEPSHA256PlaintextSize = keySizeInBits / 8 - 2 * SHA256.byteCount - 2

    private static let keyPair: KeyPair = {
        do {
            return try makeKeyPair()
        } catch {
            fatalError("RSA key pair generation failed: \(error)")
        }
    }()

    static func publicKeyJWK(
        alg: String = "RSA-OAEP-256",
        n: String = keyPair.modulus.base64URLEncodedString,
        e: String = keyPair.exponent.base64URLEncodedString
    ) -> RecoveryPublicKeyDTO.Response {
        RecoveryPublicKeyDTO.Response(kty: "RSA", use: "enc", alg: alg, kid: "kms-recovery-key", n: n, e: e)
    }

    static var modulus: Data {
        keyPair.modulus
    }

    static func decrypt(base64Ciphertext: String) throws -> Data {
        let ciphertext = try #require(Data(base64Encoded: base64Ciphertext))

        var error: Unmanaged<CFError>?
        let plaintext = SecKeyCreateDecryptedData(keyPair.privateKey, .rsaEncryptionOAEPSHA256, ciphertext as CFData, &error)

        return try #require(plaintext as Data?, "RSA-OAEP-SHA256 decryption failed: \(String(describing: error?.takeRetainedValue()))")
    }
}

// MARK: - Key generation

private extension RSAKeyPairFixture {
    final class KeyPair: @unchecked Sendable {
        let privateKey: SecKey
        let modulus: Data
        let exponent: Data

        init(privateKey: SecKey, modulus: Data, exponent: Data) {
            self.privateKey = privateKey
            self.modulus = modulus
            self.exponent = exponent
        }
    }

    struct GenerationError: Error {
        let underlying: CFError?
    }

    static func makeKeyPair() throws -> KeyPair {
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: keySizeInBits,
            kSecAttrIsPermanent: false,
        ]

        var error: Unmanaged<CFError>?
        guard
            let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
            let publicKey = SecKeyCopyPublicKey(privateKey),
            let publicKeyPKCS1 = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
        else {
            throw GenerationError(underlying: error?.takeRetainedValue())
        }

        let (modulus, exponent) = try DER.rsaPublicKeyComponents(publicKeyPKCS1)

        return KeyPair(privateKey: privateKey, modulus: modulus, exponent: exponent)
    }
}

// MARK: - DER

private enum DER {
    enum ParsingError: Error {
        case unexpectedTag(UInt8)
        case truncated
    }

    static func rsaPublicKeyComponents(_ der: Data) throws -> (modulus: Data, exponent: Data) {
        var reader = Reader(der)
        try reader.expect(tag: 0x30)
        _ = try reader.readLength()

        let modulus = try reader.readInteger()
        let exponent = try reader.readInteger()

        return (modulus, exponent)
    }

    struct Reader {
        private let bytes: [UInt8]
        private var index = 0

        init(_ data: Data) {
            bytes = Array(data)
        }

        mutating func expect(tag: UInt8) throws {
            let actual = try next()
            guard actual == tag else {
                throw ParsingError.unexpectedTag(actual)
            }
        }

        mutating func readLength() throws -> Int {
            let first = try next()
            guard first & 0x80 != 0 else {
                return Int(first)
            }

            var length = 0
            for _ in 0 ..< Int(first & 0x7F) {
                length = length << 8 | Int(try next())
            }
            return length
        }

        mutating func readInteger() throws -> Data {
            try expect(tag: 0x02)
            let length = try readLength()
            guard index + length <= bytes.count else {
                throw ParsingError.truncated
            }

            let value = bytes[index ..< index + length]
            index += length

            return Data(value.drop(while: { $0 == 0 }))
        }

        private mutating func next() throws -> UInt8 {
            guard index < bytes.count else {
                throw ParsingError.truncated
            }

            defer { index += 1 }
            return bytes[index]
        }
    }
}
