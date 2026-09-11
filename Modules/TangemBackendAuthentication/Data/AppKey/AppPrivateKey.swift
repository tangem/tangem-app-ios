//
//  AppPrivateKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import struct Foundation.Data
import Security

struct AppPrivateKey: @unchecked Sendable {
    let secKey: SecKey

    init(_ base64EncodedAppPrivateKey: String) throws(AppPrivateKeyParsingError) {
        let derEncodedKey = try Self.decodeBase64(base64EncodedAppPrivateKey)
        let derEncodedKeyPKCS1 = Self.stripPKCS8PrefixIfPresent(from: derEncodedKey)

        secKey = try Self.makeRSAPrivateKey(from: derEncodedKeyPKCS1)
    }
}

extension AppPrivateKey {
    private static func decodeBase64(_ appPrivateKey: String) throws(AppPrivateKeyParsingError) -> Data {
        guard let derEncodedKey = Data(base64Encoded: appPrivateKey) else {
            throw AppPrivateKeyParsingError.invalidBase64Encoding
        }

        return derEncodedKey
    }

    private static func stripPKCS8PrefixIfPresent(from derEncodedKey: Data) -> Data {
        // https://github.com/apple/swift-crypto/blob/3.8.0/Sources/_CryptoExtras/RSA/RSA_security.swift#L299

        precondition(derEncodedKey.startIndex == 0)

        guard
            derEncodedKey.count >= 4 + Data.partialPKCS8Prefix.count + 4,
            derEncodedKey[0] == 0x30,
            derEncodedKey[1] == 0x82
        else {
            return derEncodedKey
        }

        let outerLength = Int(derEncodedKey[2]) << 8 | Int(derEncodedKey[3])

        guard
            outerLength == derEncodedKey.count - 4,
            derEncodedKey.dropFirst(4).prefix(Data.partialPKCS8Prefix.count) == Data.partialPKCS8Prefix
        else {
            return derEncodedKey
        }

        let octetStringTagOffset = 4 + Data.partialPKCS8Prefix.count

        guard
            derEncodedKey[octetStringTagOffset] == 0x04,
            derEncodedKey[octetStringTagOffset + 1] == 0x82
        else {
            return derEncodedKey
        }

        let octetStringLength = Int(derEncodedKey[octetStringTagOffset + 2]) << 8 | Int(derEncodedKey[octetStringTagOffset + 3])

        guard octetStringLength == derEncodedKey.count - octetStringTagOffset - 4 else {
            return derEncodedKey
        }

        return derEncodedKey.dropFirst(octetStringTagOffset + 4)
    }

    private static func makeRSAPrivateKey(from derEncodedKeyPKCS1: Data) throws(AppPrivateKeyParsingError) -> SecKey {
        // https://github.com/apple/swift-crypto/blob/3.8.0/Sources/_CryptoExtras/RSA/RSA_security.swift#L103
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        ]

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(derEncodedKeyPKCS1 as CFData, attributes as CFDictionary, &error) else {
            throw .invalidKeyFormat(underlying: error!.takeRetainedValue() as any Error)
        }

        return key
    }
}

private extension Data {
    /// https://github.com/apple/swift-crypto/blob/3.8.0/Sources/_CryptoExtras/RSA/RSA_security.swift#L290
    static let partialPKCS8Prefix = Data(
        [
            0x02, 0x01, 0x00, // Version, INTEGER 0
            0x30, 0x0d, // SEQUENCE, length 13
            0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, // rsaEncryption OID
            0x05, 0x00, // NULL
        ]
    )
}
