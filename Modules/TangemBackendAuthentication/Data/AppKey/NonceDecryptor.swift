//
//  NonceDecryptor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
private import Security

struct NonceDecryptor: Sendable {
    private let parseAppPrivateKeyResult: Result<AppPrivateKey, AppPrivateKeyParsingError>

    init(appPrivateKey: String) {
        parseAppPrivateKeyResult = Self.parse(appPrivateKey: appPrivateKey)
    }

    func decrypt(cipheredNonce: Data) throws(NonceDecryptorError) -> Data {
        let parsedAppPrivateKey: AppPrivateKey

        do {
            parsedAppPrivateKey = try parseAppPrivateKeyResult.get()
        } catch {
            throw NonceDecryptorError.appPrivateKeyParsingFailed(error)
        }

        return try Self.decrypt(cipheredNonce, using: parsedAppPrivateKey)
    }

    private static func parse(appPrivateKey: String) -> Result<AppPrivateKey, AppPrivateKeyParsingError> {
        do {
            return try .success(AppPrivateKey(appPrivateKey))
        } catch {
            return .failure(error)
        }
    }

    private static func decrypt(_ cipheredNonce: Data, using appPrivateKey: AppPrivateKey) throws(NonceDecryptorError) -> Data {
        // https://github.com/apple/swift-crypto/blob/3.8.0/Sources/_CryptoExtras/RSA/RSA_security.swift#L196-L207

        var error: Unmanaged<CFError>?
        guard let decryptedNonce = SecKeyCreateDecryptedData(
            appPrivateKey.secKey,
            SecKeyAlgorithm.rsaEncryptionOAEPSHA256,
            cipheredNonce as CFData,
            &error
        ) else {
            throw NonceDecryptorError.decryptFailed(underlying: error!.takeRetainedValue() as any Error)
        }

        return decryptedNonce as Data
    }
}
