//
//  CommonUserWalletListService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import CryptoKit
import Combine
import TangemSdk

class CommonUserWalletListService: UserWalletListService {
    private typealias UserWalletDerivedKeys = [Data: [DerivationPath: ExtendedPublicKey]]
    private typealias UserWalletListDerivedKeys = [Data: UserWalletDerivedKeys]

    private enum UnlockingMethod {
        case biometry(encryptionKey: SymmetricKey)
        case userWallet(id: Data, encryptionKey: SymmetricKey)
    }

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
    private let encryptionKeyStorageKey = "user_wallet_encryption_key"

    private var unlockingMethod: UnlockingMethod?

    private let secureStorage = SecureStorage()
    private let derivedKeysStorageKey = "user_wallet_list_derived_keys"

    private var fileManager: FileManager {
        FileManager.default
    }
    private var userWalletDirectoryUrl: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("user_wallets", isDirectory: true)
    }

    private var bag: Set<AnyCancellable> = []

    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    init() {

    }

    func initialize() {

    }

    func tryToAccessBiometry(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        if case .biometry = unlockingMethod {
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

    func unlockWithCard(_ userWallet: UserWallet, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        if !userWallet.isLocked {
            completion(.success(()))
            return
        }

        unlockWithCard(completion: completion)
    }

    func unlockWithCard(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        if case .biometry = unlockingMethod {
            completion(.success(()))
            return
        }

        cardsRepository.scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                if case let .failure(error) = result {
//                    print("Failed to scan card: \(error)")
//                    self?.isScanningCard = false
//                    self?.failedCardScanTracker.recordFailure()

//                    if self?.failedCardScanTracker.shouldDisplayAlert ?? false {
//                        self?.showTroubleshootingView = true
//                    } else {
//                        switch error.toTangemSdkError() {
//                        case .unknownError, .cardVerificationFailed:
//                            self?.error = error.alertBinder
//                        default:
//                            break
//                        }
//                    }
                }
                switch result {
                case .failure(let error):
                    completion(.failure(error.toTangemSdkError()))
                case .finished:
                    break
                }
            } receiveValue: { [weak self] cardModel in
//                self?.isScanningCard = false
//                self?.failedCardScanTracker.resetCounter()
                self?.processScannedCard(cardModel)
                completion(.success(()))
            }
            .store(in: &bag)
    }

    private func processScannedCard(_ cardModel: CardViewModel) {
        let card = cardModel.card

        let userWallet = UserWallet(userWalletId: card.cardPublicKey, name: "", card: card, walletData: cardModel.walletData, artwork: nil, keys: cardModel.derivedKeys, isHDWalletAllowed: card.settings.isHDWalletAllowed)

        if let encryptionKey = userWallet.encryptionKey {
            self.unlockingMethod = .userWallet(id: userWallet.userWalletId, encryptionKey: encryptionKey)
        } else {
            return
        }

        selectedUserWalletId = userWallet.userWalletId

        if userWallets.isEmpty {
            loadModels()
        } else {
            guard let userWalletIndex = userWallets.firstIndex(where: { $0.userWalletId == userWallet.userWalletId }) else {
                return
            }

            userWallets[userWalletIndex] = userWallet
            models[userWalletIndex] = cardModel
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
        if userWallets.isEmpty {
            selectedUserWalletId = userWallet.userWalletId
        }

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
        for i in 0 ..< userWallets.count {
            if userWallets[i].userWalletId == userWallet.userWalletId {
                userWallets[i].name = name
            }
        }

        models.forEach {
            if $0.userWallet.userWalletId == userWallet.userWalletId {
                $0.setName(name)
            }
        }

        saveUserWallets(userWallets)
    }

    func clear() {
        let _ = saveUserWallets([])
        userWallets = []
        selectedUserWalletId = nil
        unlockingMethod = nil
        do {
            try biometricsStorage.delete(encryptionKeyStorageKey)
        } catch {
            print("Failed to delete user wallet list encryption key: \(error)")
        }
    }

    private func tryToAccessBiometryInternal(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        biometricsStorage.get(encryptionKeyStorageKey) { [weak self, encryptionKeyStorageKey] result in
            switch result {
            case .success(let encryptionKey):
                if let encryptionKey = encryptionKey {
                    self?.unlockingMethod = .biometry(encryptionKey: SymmetricKey(data: encryptionKey))
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

            self?.biometricsStorage.store(newEncryptionKeyData, forKey: encryptionKeyStorageKey, overwrite: true) { [weak self] result in
                switch result {
                case .success:
                    self?.unlockingMethod = .biometry(encryptionKey: SymmetricKey(data: newEncryptionKey))
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

            let encryptionKeys: [Data: Data]

            if case let .biometry(encryptionKey) = unlockingMethod,
               fileManager.fileExists(atPath: userWalletEncryptionKeysPath().path)
            {
                let encryptionKeysDataEncrypted = try Data(contentsOf: userWalletEncryptionKeysPath())
                let encryptionKeysData = try decrypt(encryptionKeysDataEncrypted, with: encryptionKey)
                encryptionKeys = try decoder.decode([Data: Data].self, from: encryptionKeysData)
            } else {
                encryptionKeys = [:]
            }

            for i in 0 ..< userWallets.count {
                let userWallet = userWallets[i]

                let userWalletEncryptionKey: SymmetricKey

                if case let .userWallet(id, encryptionKey) = self.unlockingMethod,
                   userWallet.userWalletId == id
                {
                    userWalletEncryptionKey = encryptionKey
                } else if let userWalletEncryptionKeyData = encryptionKeys[userWallet.userWalletId] {
                    userWalletEncryptionKey = SymmetricKey(data: userWalletEncryptionKeyData)
                } else {
                    print("Failed to find encryption key for wallet", userWallet.userWalletId.hex)
                    continue
                }

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
                if fileManager.fileExists(atPath: userWalletDirectoryUrl.path) {
                    try fileManager.removeItem(at: userWalletDirectoryUrl)
                }
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

            if case let .biometry(encryptionKey) = unlockingMethod {
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
            print("Failed to save user wallets", error)
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
