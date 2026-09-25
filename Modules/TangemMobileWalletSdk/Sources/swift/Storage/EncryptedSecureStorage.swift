//
//  EncryptedSecureStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import TangemFoundation

/// A storage service that encrypts data using Secure Enclave and AES encryption.
final class EncryptedSecureStorage {
    private let secureStorage: MobileWalletSecureStorage
    private let secureEnclaveService: MobileWalletSecureEnclaveService

    init(
        secureStorage: MobileWalletSecureStorage = SecureStorage(),
        secureEnclaveService: MobileWalletSecureEnclaveService = SecureEnclaveService()
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeData(
        _ data: Data,
        keyTag: String,
        secureEnclaveKeyTag: String,
        accessCode: String?
    ) throws {
        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            data,
            keyTag: secureEnclaveKeyTag
        )

        let encryptedAesKey = switch accessCode {
        case .some(let code):
            try AESEncoder.encryptWithPassword(
                password: code,
                content: secureEnclaveEncryptedKey
            )
        case .none:
            secureEnclaveEncryptedKey
        }

        try secureStorage.store(encryptedAesKey, forKey: keyTag)
    }

    func getData(
        keyTag: String,
        secureEnclaveKeyTag: String,
        accessCode: String?
    ) throws -> Data {
        guard let encryptedAesKey = try secureStorage.get(keyTag) else {
            throw PrivateInfoStorageError.noInfo(tag: keyTag)
        }

        let secureEnclaveEncryptedKey: Data
        switch accessCode {
        case .some(let code):
            do {
                secureEnclaveEncryptedKey = try AESEncoder.decryptWithPassword(
                    password: code,
                    encryptedData: encryptedAesKey
                )
            } catch CryptoKitError.authenticationFailure, EncodingError.invalidPassword {
                // Only a failed GCM tag check (or an unusable password string) means the access code itself is wrong.
                throw MobileWalletUnlockError.wrongAccessCode
            }
        case .none:
            secureEnclaveEncryptedKey = encryptedAesKey
        }

        // Past this point the access code is correct. If the Secure Enclave cannot unwrap the key, the SE
        // key is gone or unusable (e.g. purged by iOS together with the device passcode) — that is a storage
        // failure, not a wrong code, and no code the user could enter would fix it.
        do {
            return try secureEnclaveService.decryptData(
                secureEnclaveEncryptedKey,
                keyTag: secureEnclaveKeyTag
            )
        } catch {
            throw MobileWalletUnlockError.keyStorageUnavailable
        }
    }

    func deleteData(keyTag: String, secureEnclaveKeyTag: String) throws {
        secureEnclaveService.delete(tag: secureEnclaveKeyTag)
        try secureStorage.delete(keyTag)
    }
}
