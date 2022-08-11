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

    private let biometricStorage = BiometricsStorage()
    private let keychainKey = "user_wallet_list_service"
    private var encryptionKey: Data?

    private let secureStorage = SecureStorage()
    private let derivedKeysStorageKey = "user_wallet_list_derived_keys"

    init() {

    }

    func initialize() {

    }

    func tryToAccessBiometry(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard encryptionKey == nil else { return }

        biometricStorage.get(keychainKey) { [weak self, keychainKey] result in
            switch result {
            case .success(let encryptionKey):
                if let encryptionKey = encryptionKey {
                    self?.encryptionKey = encryptionKey
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

            self?.biometricStorage.store(newEncryptionKeyData, forKey: keychainKey, overwrite: true) { [weak self] result in
                switch result {
                case .success:
                    self?.encryptionKey = newEncryptionKeyData
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

    private func savedUserWallets() -> [UserWallet] {
        do {
            let userWalletsData = AppSettings.shared.userWallets
            var userWallets = try JSONDecoder().decode([UserWallet].self, from: userWalletsData)

            if let encryptionKey = encryptionKey,
               let derivedKeysData = try secureStorage.get(derivedKeysStorageKey)
            {
                let derivedKeysList = try JSONDecoder().decode(UserWalletListDerivedKeys.self, from: derivedKeysData)
                for i in 0 ..< userWallets.count {
                    userWallets[i].keys = derivedKeysList[userWallets[i].userWalletId] ?? [:]
                }
            }

            return userWallets
        } catch {
            print(error)
            return []
        }
    }

    private func saveUserWallets(_ userWallets: [UserWallet]) {
        do {
            let derivedKeys: UserWalletListDerivedKeys = userWallets.reduce(into: [:]) { partialResult, userWallet in
                partialResult[userWallet.userWalletId] = userWallet.keys
            }
            let derivedKeysData = try JSONEncoder().encode(derivedKeys)

            try secureStorage.store(derivedKeysData, forKey: derivedKeysStorageKey, overwrite: true)

            let userWalletsWithoutKeys: [UserWallet] = userWallets.map {
                var userWalletWithoutKeys = $0
                userWalletWithoutKeys.keys = [:]
                return userWalletWithoutKeys
            }

            let userWalletsData = try JSONEncoder().encode(userWalletsWithoutKeys)
            AppSettings.shared.userWallets = userWalletsData
        } catch {
            print(error)
        }
    }
}
