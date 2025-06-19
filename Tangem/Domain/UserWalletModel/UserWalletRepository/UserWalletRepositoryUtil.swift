//
//  UserWalletRepositoryUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import TangemHotSdk

class UserWalletRepositoryUtil {
    private var fileManager: FileManager {
        FileManager.default
    }

    private var userWalletDirectoryUrl: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("user_wallets", isDirectory: true)
    }

    private let publicDataEncryptionKeyStorageKey = "user_wallet_public_data_encryption_key"

    func removePublicDataEncryptionKey() {
        do {
            let secureStorage = SecureStorage()
            try secureStorage.delete(publicDataEncryptionKeyStorageKey)
        } catch {
            AppLogger.error("Failed to erase public data encryption key", error: error)
        }
    }

    func savedUserWallets(encryptionKeyByUserWalletId: [UserWalletId: UserWalletEncryptionKey]) -> [StoredUserWallet] {
        do {
            guard fileManager.fileExists(atPath: userWalletListPath().path) else {
                AppLogger.warning("Detected empty saved user wallets")
                return []
            }

            let decoder = JSONDecoder.tangemSdkDecoder

            let userWalletsPublicDataEncrypted = try Data(contentsOf: userWalletListPath())
            let userWalletsPublicData = try decrypt(userWalletsPublicDataEncrypted, with: publicDataEncryptionKey())
            var userWallets = try decoder.decode([StoredUserWallet].self, from: userWalletsPublicData)

            for i in 0 ..< userWallets.count {
                let userWallet = userWallets[i]
                let userWalletId = UserWalletId(value: userWallet.userWalletId)
                guard let userWalletEncryptionKey = encryptionKeyByUserWalletId[userWalletId] else {
                    continue
                }

                let sensitiveInformationEncryptedData = try Data(contentsOf: userWalletPath(for: userWalletId))
                let sensitiveInformationData = try decrypt(sensitiveInformationEncryptedData, with: userWalletEncryptionKey)

                switch userWallet.walletInfo {
                case .card:
                    let sensitiveInformation = try decoder.decode(
                        StoredUserWallet.SensitiveInformation<CardDTO.Wallet>.self,
                        from: sensitiveInformationData
                    )
                    userWallets[i] = userWallet.updatingWallets(sensitiveInformation.wallets)
                case .hotWallet:
                    let sensitiveInformation = try decoder.decode(
                        StoredUserWallet.SensitiveInformation<HotWallet>.self,
                        from: sensitiveInformationData
                    )
                    userWallets[i] = userWallet.updatingWallets(sensitiveInformation.wallets)
                }
            }

            return userWallets
        } catch {
            AppLogger.error(error: error)
            return []
        }
    }

    func saveUserWallets(_ userWallets: [StoredUserWallet]) {
        let encoder = JSONEncoder.tangemSdkEncoder

        do {
            if userWallets.isEmpty {
                if fileManager.fileExists(atPath: userWalletDirectoryUrl.path) {
                    try fileManager.removeItem(at: userWalletDirectoryUrl)
                }
                return
            }

            try fileManager.createDirectory(at: userWalletDirectoryUrl, withIntermediateDirectories: true)

            let userWalletsWithoutSensitiveInformation: [StoredUserWallet] = userWallets.map {
                $0.resettingWallets()
            }

            let publicData = try encoder.encode(userWalletsWithoutSensitiveInformation)
            let publicDataEncrypted = try encrypt(publicData, with: publicDataEncryptionKey())
            try publicDataEncrypted.write(to: userWalletListPath(), options: .atomic)
            try excludeFromBackup(url: userWalletListPath())

            for userWallet in userWallets {
                guard let encryptionKey = UserWalletEncryptionKeyFactory().encryptionKey(for: userWallet) else {
                    AppLogger.error(error: "User wallet failed to generate encryption key")
                    continue
                }

                let sensitiveInformation: any Encodable

                switch userWallet.walletInfo {
                case .card(let cardDTO):
                    sensitiveInformation = StoredUserWallet.SensitiveInformation(wallets: cardDTO.wallets)
                case .hotWallet(let hotWallet):
                    sensitiveInformation = StoredUserWallet.SensitiveInformation(wallets: hotWallet.wallets)
                }

                let sensitiveDataEncrypted = try encrypt(encoder.encode(sensitiveInformation), with: encryptionKey)
                let sensitiveDataPath = userWalletPath(for: UserWalletId(value: userWallet.userWalletId))
                try sensitiveDataEncrypted.write(to: sensitiveDataPath, options: .atomic)
                try excludeFromBackup(url: sensitiveDataPath)
            }
            AppLogger.info("User wallets were saved successfully")
        } catch {
            AppLogger.error("Failed to save user wallets", error: error)
        }
    }

    private func publicDataEncryptionKey() throws -> UserWalletEncryptionKey {
        let secureStorage = SecureStorage()

        let encryptionKeyData = try secureStorage.get(publicDataEncryptionKeyStorageKey)
        if let encryptionKeyData {
            let symmetricKey: SymmetricKey = .init(data: encryptionKeyData)
            return UserWalletEncryptionKey(symmetricKey: symmetricKey)
        }

        let newEncryptionKey = SymmetricKey(size: .bits256)
        try secureStorage.store(newEncryptionKey.dataRepresentationWithHexConversion, forKey: publicDataEncryptionKeyStorageKey)
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
