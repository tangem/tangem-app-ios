//
//  CommonUserWalletListService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk

class CommonUserWalletListService: UserWalletListService {
    private typealias UserWalletDerivedKeys = [Data: [DerivationPath: ExtendedPublicKey]]
    private typealias UserWalletListDerivedKeys = [Data: UserWalletDerivedKeys]

    var models: [CardViewModel] = []

    var selectedModel: CardViewModel? {
        return models.first {
            $0.userWallet.userWalletId == selectedUserWalletId
        }
    }

    var selectedUserWalletId: Data? {
        get {
            let id = AppSettings.shared.selectedUserWalletId
            return id.isEmpty ? nil : id
        }
        set {
            AppSettings.shared.selectedUserWalletId = newValue ?? Data()
        }
    }

    var isEmpty: Bool {
        savedUserWallets().isEmpty
    }

    private var userWallets: [UserWallet] = []

    private let biometricsStorage = BiometricsStorage()
    private let keychainKey = "user_wallet_list_service"
    private var encryptionKey: SymmetricKey?

    private let secureStorage = SecureStorage()
    private let derivedKeysStorageKey = "user_wallet_list_derived_keys"

    private var fileManager: FileManager {
        FileManager.default
    }
    private var userWalletDirectoryUrl: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("user_wallets", isDirectory: true)
    }

    init() {

    }

    func initialize() {

    }

    func tryToAccessBiometry(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard encryptionKey == nil else {
            print("Encryption key already fetched, skipping biometric authentication")
            completion(.success(()))
            return
        }

        tryToAccessBiometryInternal { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    func loadModels() {
        self.userWallets = savedUserWallets()
        models = userWallets.map {
            CardViewModel(userWallet: $0)
        }
    }

    func deleteWallet(_ userWallet: UserWallet) {
        let userWalletId = userWallet.userWalletId
        userWallets.removeAll { $0.userWalletId == userWalletId }
        models.removeAll { $0.userWallet.userWalletId == userWalletId }
        saveUserWallets(userWallets)
    }

    func contains(_ userWallet: UserWallet) -> Bool {
        userWallets.contains { $0.userWalletId == userWallet.userWalletId }
    }

    func save(_ userWallet: UserWallet) -> Bool {
        if let index = userWallets.firstIndex(where: { $0.userWalletId == userWallet.userWalletId }) {
            userWallets[index] = userWallet
        } else {
            userWallets.append(userWallet)
        }

        saveUserWallets(userWallets)

        if userWallets.count == 1 {
            selectedUserWalletId = userWallet.userWalletId
        }

        let newModel = CardViewModel(userWallet: userWallet)
        if let index = models.firstIndex(where: { $0.userWallet.userWalletId == userWallet.userWalletId }) {
            models[index] = newModel
        } else {
            models.append(newModel)
        }

        return true
    }

    func setName(_ userWallet: UserWallet, name: String) {
        for i in 0 ..< userWallets.count {
            if userWallets[i].userWalletId == userWallet.userWalletId {
                userWallets[i].name = name
            }
        }

        models.forEach {
            if $0.userWallet.userWalletId == userWallet.userWalletId {
                $0.cardInfo.name = name
            }
        }

        saveUserWallets(userWallets)
    }

    func clear() {
        let _ = saveUserWallets([])
        selectedUserWalletId = nil
        encryptionKey = nil
    }

    private func tryToAccessBiometryInternal(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        biometricsStorage.get(keychainKey) { [weak self, keychainKey] result in
            switch result {
            case .success(let encryptionKey):
                if let encryptionKey = encryptionKey {
                    self?.encryptionKey = SymmetricKey(data: encryptionKey)
                    self?.loadModels()
                    completion(.success(()))
                    return
                }
            case .failure(let error):
                print("Failed to get encryption key", error)
                self?.loadModels()
                completion(.failure(error))
                return
            }

            let newEncryptionKey = SymmetricKey(size: .bits256)
            let newEncryptionKeyData = Data(hexString: newEncryptionKey.dataRepresentation.hexString) // WTF?

            self?.biometricsStorage.store(newEncryptionKeyData, forKey: keychainKey, overwrite: true) { [weak self] result in
                switch result {
                case .success:
                    self?.encryptionKey = SymmetricKey(data: newEncryptionKeyData)
                    completion(.success(()))
                case .failure(let error):
                    print("Failed to save encryption key", error)
                    completion(.failure(error))
                }

                self?.loadModels()
            }
        }
    }

    private func savedUserWallets() -> [UserWallet] {
        do {
            guard fileManager.fileExists(atPath: userWalletListPath().path) else {
                return []
            }

            let decoder = JSONDecoder()

            let userWalletsPublicData = try Data(contentsOf: userWalletListPath())
            var userWallets = try decoder.decode([UserWallet].self, from: userWalletsPublicData)

            guard
                let encryptionKey = encryptionKey,
                fileManager.fileExists(atPath: userWalletEncryptionKeysPath().path)
            else {
                return userWallets
            }

            let encryptionKeysDataEncrypted = try Data(contentsOf: userWalletEncryptionKeysPath())
            let encryptionKeysData = try decrypt(encryptionKeysDataEncrypted, with: encryptionKey)
            let encryptionKeys = try decoder.decode([Data: Data].self, from: encryptionKeysData)

            for i in 0 ..< userWallets.count {
                let userWallet = userWallets[i]

                guard let userWalletEncryptionKeyData = encryptionKeys[userWallet.userWalletId] else {
                    print("Failed to find encryption key for wallet", userWallet.userWalletId.hex)
                    continue
                }

                let userWalletEncryptionKey = SymmetricKey(data: userWalletEncryptionKeyData)

                let sensitiveInformationEncryptedData = try Data(contentsOf: userWalletPath(for: userWallet))
                let sensitiveInformationData = try decrypt(sensitiveInformationEncryptedData, with: userWalletEncryptionKey)
                let sensitiveInformation = try decoder.decode(UserWallet.SensitiveInformation.self, from: sensitiveInformationData)

                var card = userWallet.card
                card.wallets = sensitiveInformation.wallets
                userWallets[i].card = card

                userWallets[i].keys = sensitiveInformation.keys
            }

            return userWallets
        } catch {
            print(error)
            return []
        }
    }

    private func saveUserWallets(_ userWallets: [UserWallet]) {
        let encoder = JSONEncoder()

        do {
            if userWallets.isEmpty {
                try fileManager.removeItem(at: userWalletDirectoryUrl)
                return
            }

            try fileManager.createDirectory(at: userWalletDirectoryUrl, withIntermediateDirectories: true)

            let userWalletsWithoutKeys: [UserWallet] = userWallets.map {
                var userWalletWithoutKeys = $0
                userWalletWithoutKeys.keys = [:]

                var card = $0.card
                card.wallets = []
                userWalletWithoutKeys.card = card

                return userWalletWithoutKeys
            }

            let publicData = try encoder.encode(userWalletsWithoutKeys)
            try publicData.write(to: userWalletListPath(), options: .atomic)
            try excludeFromBackup(url: userWalletListPath())


            let encryptionKeys: [Data: Data] = Dictionary(userWallets.compactMap {
                guard let encryptionKey = $0.encryptionKey else { return nil }
                let encryptionKeyData = Data(hex: encryptionKey.dataRepresentation.hex) // WTF?
                return ($0.userWalletId, encryptionKeyData)
            }) { v1, _ in
                v1
            }

            if let encryptionKey = encryptionKey {
                let encryptionKeysPlain = try encoder.encode(encryptionKeys)
                let encryptionKeysEncrypted = try encrypt(encryptionKeysPlain, with: encryptionKey)
                try encryptionKeysEncrypted.write(to: userWalletEncryptionKeysPath(), options: .atomic)
                try excludeFromBackup(url: userWalletEncryptionKeysPath())
            }


            for userWallet in userWallets {
                guard let userWalletEncryptionKey = userWallet.encryptionKey else {
                    print("User wallet \(userWallet.card.cardId) failed to generate encryption key")
                    continue
                }

                let sensitiveInformation = UserWallet.SensitiveInformation(keys: userWallet.keys, wallets: userWallet.card.wallets)
                let sensitiveDataEncoded = try encrypt(encoder.encode(sensitiveInformation), with: userWalletEncryptionKey)
                let sensitiveDataPath = userWalletPath(for: userWallet)
                try sensitiveDataEncoded.write(to: sensitiveDataPath, options: .atomic)
                try excludeFromBackup(url: sensitiveDataPath)
            }
        } catch {
            print(error)
        }
    }

    private func userWalletEncryptionKeysPath() -> URL {
        userWalletDirectoryUrl.appendingPathComponent("encryption_keys.bin")
    }

    private func userWalletListPath() -> URL {
        userWalletDirectoryUrl.appendingPathComponent("user_wallets.json")
    }

    private func userWalletPath(for userWallet: UserWallet) -> URL {
        return userWalletDirectoryUrl.appendingPathComponent("user_wallet_\(userWallet.userWalletId.hex).bin")
    }

    private func excludeFromBackup(url originalUrl: URL) throws {
        var url = originalUrl

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func decrypt(_ data: Data, with key: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
        return decryptedData
    }

    private func encrypt(_ data: Data, with key: SymmetricKey) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: key)
        let sealedData = sealedBox.combined
        return sealedData
    }
}
