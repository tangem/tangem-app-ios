//
//  RecoveryKeyEncryptor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Security
import TangemFoundation

/// Encrypts the social backup recovery key `K` with the KMS recovery public key.
struct RecoveryKeyEncryptor {
    /// - Parameters:
    ///   - recoveryKey: raw social backup recovery key `K`.
    ///   - publicKey: KMS recovery public key (JWK).
    /// - Returns: Base64 of `recoveryKey` encrypted with the JWK's RSA key (RSA-OAEP-256).
    func encrypt(
        recoveryKey: Data,
        publicKey: RecoveryPublicKeyDTO.Response
    ) throws(RecoveryKeyEncryptionError) -> String {
        guard publicKey.alg == Constants.supportedAlgorithm else {
            throw .unsupportedAlgorithm(publicKey.alg)
        }

        guard
            let modulus = publicKey.n.base64URLDecodedData(),
            let exponent = publicKey.e.base64URLDecodedData()
        else {
            throw .invalidPublicKey
        }

        let secKey = try makeRSAPublicKey(modulus: modulus, exponent: exponent)

        let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA256
        guard SecKeyIsAlgorithmSupported(secKey, .encrypt, algorithm) else {
            throw .invalidPublicKey
        }

        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(secKey, algorithm, recoveryKey as CFData, &error) else {
            throw .encryptionFailed(code: (error?.takeRetainedValue()).map(CFErrorGetCode))
        }

        return (encrypted as Data).base64EncodedString()
    }
}

// MARK: - Private

private extension RecoveryKeyEncryptor {
    /// `SecKeyCreateWithData` expects an RSA public key as PKCS#1 DER:
    /// `RSAPublicKey ::= SEQUENCE { modulus INTEGER, publicExponent INTEGER }`.
    func makeRSAPublicKey(modulus: Data, exponent: Data) throws(RecoveryKeyEncryptionError) -> SecKey {
        let der = DER.sequence(DER.unsignedInteger(modulus) + DER.unsignedInteger(exponent))

        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
        ]

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(der as CFData, attributes as CFDictionary, &error) else {
            throw .invalidPublicKey
        }

        return key
    }

    enum Constants {
        static let supportedAlgorithm = "RSA-OAEP-256"
    }

    enum DER {
        static func sequence(_ content: Data) -> Data {
            Data([0x30]) + length(of: content.count) + content
        }

        /// DER INTEGER holding a big-endian unsigned value: leading zeros are stripped,
        /// and a zero byte is prepended when the top bit is set so the value stays positive.
        static func unsignedInteger(_ value: Data) -> Data {
            var bytes = value.drop(while: { $0 == 0 })
            if bytes.isEmpty {
                bytes = Data([0])
            }
            if let first = bytes.first, first & 0x80 != 0 {
                bytes = Data([0]) + bytes
            }
            return Data([0x02]) + length(of: bytes.count) + bytes
        }

        static func length(of count: Int) -> Data {
            if count < 0x80 {
                return Data([UInt8(count)])
            }

            var lengthBytes: [UInt8] = []
            var remaining = count
            while remaining > 0 {
                lengthBytes.insert(UInt8(remaining & 0xFF), at: 0)
                remaining >>= 8
            }
            return Data([0x80 | UInt8(lengthBytes.count)]) + Data(lengthBytes)
        }
    }
}

// MARK: - RecoveryKeyEncryptionError

enum RecoveryKeyEncryptionError: Error, LocalizedError {
    case unsupportedAlgorithm(String)
    case invalidPublicKey
    case encryptionFailed(code: Int?)

    var errorDescription: String? {
        switch self {
        case .unsupportedAlgorithm(let algorithm):
            "The recovery public key algorithm is not supported: \(algorithm)"
        case .invalidPublicKey:
            "The recovery public key is invalid"
        case .encryptionFailed(let code):
            "Failed to encrypt the recovery key (code: \(code.map(String.init) ?? "unknown"))"
        }
    }
}
