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

    private let biometricsStorage = BiometricsStorage()
    private let keychainKey = "user_wallet_list_service"
    private var encryptionKey: SymmetricKey?

    private let secureStorage = SecureStorage()
    private let derivedKeysStorageKey = "user_wallet_list_derived_keys"

    init() {

    }

    func initialize() {

    }

    func tryToAccessBiometry(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard encryptionKey == nil else {
            print("Encryption key already fetched, skipping biometric authentication")
            return
        }

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

    func loadModels() {
        let userWallets = savedUserWallets()
        models = userWallets.map {
            CardViewModel(userWallet: $0)
        }
    }

    func deleteWallet(_ userWallet: UserWallet) {
        let userWalletId = userWallet.userWalletId
        var userWallets = savedUserWallets()
        userWallets.removeAll { $0.userWalletId == userWalletId }
        models.removeAll { $0.userWallet.userWalletId == userWalletId }
        saveUserWallets(userWallets)
    }

    func contains(_ userWallet: UserWallet) -> Bool {
        let userWallets = savedUserWallets()
        return userWallets.contains { $0.userWalletId == userWallet.userWalletId }
    }

    func save(_ userWallet: UserWallet) -> Bool {
        var userWallets = savedUserWallets()

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
        var userWallets = savedUserWallets()

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

    private func savedUserWallets() -> [UserWallet] {
        do {
            var userWallets: [UserWallet] = []

            let userWalletsData = AppSettings.shared.userWallets
            if !userWalletsData.isEmpty {
                userWallets = try JSONDecoder().decode([UserWallet].self, from: userWalletsData)
            }

            if let encryptionKey = encryptionKey,
               let derivedKeysEncryptedData = try secureStorage.get(derivedKeysStorageKey),
               !derivedKeysEncryptedData.isEmpty
            {
                let derivedKeysData = try decrypt(derivedKeysEncryptedData, with: encryptionKey)
                if !derivedKeysData.isEmpty {
                    let derivedKeysList = try JSONDecoder().decode(UserWalletListDerivedKeys.self, from: derivedKeysData)
                    for i in 0 ..< userWallets.count {
                        userWallets[i].keys = derivedKeysList[userWallets[i].userWalletId] ?? [:]
                    }
                }
            }

            return userWallets
        } catch {
            print(error)
            return []
        }
    }

    private func saveUserWallets(_ userWallets: [UserWallet]) {
        guard let encryptionKey = encryptionKey else {
            return
        }

        do {
            let derivedKeysEncryptedData: Data
            let userWalletsData: Data

            if userWallets.isEmpty {
                derivedKeysEncryptedData = Data()
                userWalletsData = Data()
            } else {
                let derivedKeys: UserWalletListDerivedKeys = userWallets.reduce(into: [:]) { partialResult, userWallet in
                    partialResult[userWallet.userWalletId] = userWallet.keys
                }
                let derivedKeysData = try JSONEncoder().encode(derivedKeys)
                derivedKeysEncryptedData = try encrypt(derivedKeysData, with: encryptionKey)

                let userWalletsWithoutKeys: [UserWallet] = userWallets.map {
                    var userWalletWithoutKeys = $0
                    userWalletWithoutKeys.keys = [:]
                    return userWalletWithoutKeys
                }

                userWalletsData = try JSONEncoder().encode(userWalletsWithoutKeys)
            }

            if derivedKeysEncryptedData.isEmpty {
                try secureStorage.delete(derivedKeysStorageKey)
            } else {
                try secureStorage.store(derivedKeysEncryptedData, forKey: derivedKeysStorageKey, overwrite: true)
            }
            AppSettings.shared.userWallets = userWalletsData
        } catch {
            print(error)
        }
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
