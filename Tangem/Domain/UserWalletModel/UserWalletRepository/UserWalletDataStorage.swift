//
//  UserWalletDataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import TangemMobileWalletSdk
import LocalAuthentication
import TangemFoundation

class UserWalletDataStorage {
    private let fileManager: FileManager = .default
    private let encoder = JSONEncoder.tangemSdkEncoder
    private let decoder = JSONDecoder.tangemSdkDecoder
    private let secureStorage = SecureStorage()

    private lazy var userWalletDirectoryUrl: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("user_wallets", isDirectory: true)

    // MARK: - Clear

    func clear() {
        do {
            try secureStorage.delete(Constants.publicDataEncryptionKeyStorageKey)

            if fileManager.fileExists(atPath: userWalletDirectoryUrl.path) {
                try fileManager.removeItem(at: userWalletDirectoryUrl)
            }
        } catch {
            AppLogger.error("Failed to clear", error: error)
        }
    }

    func delete(userWalletId: UserWalletId, updatedWallets: [StoredUserWallet]) {
        do {
            let userWalletSensitiveDataPath = userWalletPath(for: userWalletId)
            if fileManager.fileExists(atPath: userWalletSensitiveDataPath.path) {
                try fileManager.removeItem(at: userWalletSensitiveDataPath)
            }

            savePublicData(updatedWallets)
        } catch {
            AppLogger.error("Failed to delete", error: error)
        }
    }

    // MARK: Public data

    func fetchPublicData() -> [StoredUserWallet] {
        guard AppSettings.shared.saveUserWallets else {
            return []
        }

        do {
            let userWalletListPath = userWalletListPath()

            guard fileManager.fileExists(atPath: userWalletListPath.path) else {
                AppLogger.warning("Detected empty saved user wallets")
                return []
            }

            let userWalletsPublicDataEncrypted = try Data(contentsOf: userWalletListPath)
            let userWalletsPublicData = try decrypt(userWalletsPublicDataEncrypted, with: publicDataEncryptionKey())
            let userWallets = try decoder.decode([StoredUserWallet].self, from: userWalletsPublicData)
            return userWallets
        } catch {
            AppLogger.error(error: error)
            return []
        }
    }

    func savePublicData(_ userWallets: [StoredUserWallet]) {
        guard AppSettings.shared.saveUserWallets else {
            return
        }

        do {
            try fileManager.createDirectory(at: userWalletDirectoryUrl, withIntermediateDirectories: true)

            let publicData = try encoder.encode(userWallets)
            let publicDataEncrypted = try encrypt(publicData, with: publicDataEncryptionKey())
            try publicDataEncrypted.write(to: userWalletListPath(), options: [.atomic, .completeFileProtection])
            try excludeFromBackup(url: userWalletListPath())

            AppLogger.info("User wallets were saved successfully")
        } catch {
            AppLogger.error("Failed to save user wallets", error: error)
        }
    }

    // MARK: Private data

    func fetchPrivateData(encryptionKeys: [UserWalletId: UserWalletEncryptionKey]) -> [UserWalletId: StoredUserWallet.SensitiveInfo] {
        do {
            var privateInfos: [UserWalletId: StoredUserWallet.SensitiveInfo] = [:]

            for (userWalletId, userWalletEncryptionKey) in encryptionKeys {
                let sensitiveInformationEncryptedData = try Data(contentsOf: userWalletPath(for: userWalletId))
                let sensitiveInformationData = try decrypt(sensitiveInformationEncryptedData, with: userWalletEncryptionKey)

                let deserialized = StoredUserWallet.SensitiveInfo.deserialize(from: sensitiveInformationData, decoder: decoder)

                if let deserialized {
                    privateInfos[userWalletId] = deserialized
                }
            }

            return privateInfos
        } catch {
            AppLogger.error(error: error)
            return [:]
        }
    }

    func savePrivateData(
        sensitiveInfo: StoredUserWallet.SensitiveInfo,
        userWalletId: UserWalletId,
        encryptionKey: UserWalletEncryptionKey
    ) {
        guard AppSettings.shared.saveUserWallets else {
            return
        }

        do {
            let serialized = try sensitiveInfo.serialize(encoder: encoder)
            let sensitiveDataEncrypted = try encrypt(serialized, with: encryptionKey)
            let sensitiveDataPath = userWalletPath(for: userWalletId)
            try sensitiveDataEncrypted.write(to: sensitiveDataPath, options: [.atomic, .completeFileProtection])
            try excludeFromBackup(url: sensitiveDataPath)
        } catch {
            AppLogger.error("Failed to save user wallet private data", error: error)
        }
    }

    // MARK: Helpers

    private func publicDataEncryptionKey() throws -> UserWalletEncryptionKey {
        let encryptionKeyData = try secureStorage.get(Constants.publicDataEncryptionKeyStorageKey)
        if let encryptionKeyData {
            let symmetricKey: SymmetricKey = .init(data: encryptionKeyData)
            return UserWalletEncryptionKey(symmetricKey: symmetricKey)
        }

        let newEncryptionKey = SymmetricKey(size: .bits256)
        try secureStorage.store(newEncryptionKey.dataRepresentationWithHexConversion, forKey: Constants.publicDataEncryptionKeyStorageKey)
        return UserWalletEncryptionKey(symmetricKey: newEncryptionKey)
    }

    private func userWalletListPath() -> URL {
        userWalletDirectoryUrl.appendingPathComponent("user_wallets.bin")
    }

    private func userWalletPath(for userWalletId: UserWalletId) -> URL {
        return userWalletDirectoryUrl.appendingPathComponent("user_wallet_\(userWalletId.stringValue.lowercased()).bin")
    }

    private func excludeFromBackup(url originalUrl: URL) throws {
        var url = originalUrl

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func decrypt(_ data: Data, with key: UserWalletEncryptionKey) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: key.symmetricKey)
        return decryptedData
    }

    private func encrypt(_ data: Data, with key: UserWalletEncryptionKey) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: key.symmetricKey)
        let sealedData = sealedBox.combined
        return sealedData
    }
}

extension UserWalletDataStorage {
    enum UnlockMethod {
        case biometrics(LAContext)
        case userWallet(userWalletId: UserWalletId, key: UserWalletEncryptionKey)
    }
}

private extension UserWalletDataStorage {
    enum Constants {
        static let publicDataEncryptionKeyStorageKey = "user_wallet_public_data_encryption_key"
    }
}
