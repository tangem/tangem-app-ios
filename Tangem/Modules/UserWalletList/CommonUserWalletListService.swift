//
//  CommonUserWalletListService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import CryptoKit
import Combine
import LocalAuthentication
import TangemSdk

class CommonUserWalletListService: UserWalletListService {
    var models: [CardViewModel] {
        cardsRepository.models
    }

    var selectedModel: CardViewModel? {
        return models.first {
            $0.userWallet?.userWalletId == selectedUserWalletId
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
        savedUserWallets(withSensitiveData: false).isEmpty
    }

    private(set) var isUnlocked: Bool = false

    private var userWallets: [UserWallet] = []

    private var encryptionKeyByUserWalletId: [Data: SymmetricKey] = [:]

    private let encryptionKeyStorage = UserWalletEncryptionKeyStorage()

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

    func unlockWithBiometry(completion: @escaping (Result<Void, Error>) -> Void) {
        encryptionKeyStorage.fetch { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let keys):
                    self?.encryptionKeyByUserWalletId = keys
                    self?.loadModels()
                    self?.isUnlocked = true
                    completion(.success(()))
                }
            }
        }
    }

    func unlockWithCard(_ userWallet: UserWallet, completion: @escaping (Result<Void, Error>) -> Void) {
        guard
            let encryptionKey = userWallet.encryptionKey
        else {
            completion(.failure(TangemSdkError.cardError))
            return
        }

        encryptionKeyByUserWalletId[userWallet.userWalletId] = encryptionKey

        selectedUserWalletId = userWallet.userWalletId

        if userWallets.isEmpty {
            loadModels()
        } else if let userWalletIndex = userWallets.firstIndex(where: { $0.userWalletId == userWallet.userWalletId }) {
            userWallets[userWalletIndex] = userWallet
            cardsRepository.add(CardViewModel(userWallet: userWallet))
        } else {
            completion(.failure(TangemSdkError.cardError))
            return
        }

        if models.count == 1 {
            isUnlocked = true
        }

        completion(.success(()))
    }

    func didScan(card: CardDTO) {
        let cardId = card.cardId

        guard
            card.hasWallets,
            var userWallet = userWallets.first(where: { $0.userWalletId == card.userWalletId }),
            !userWallet.associatedCardIds.contains(cardId)
        else {
            return
        }

        userWallet.associatedCardIds.insert(cardId)
        let _ = save(userWallet)
    }

    func loadModels() {
        userWallets = savedUserWallets(withSensitiveData: true)

        let models = userWallets.map {
            CardViewModel(userWallet: $0)
        }
        cardsRepository.add(models)
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

        encryptionKeyStorage.add(userWallet)

        saveUserWallets(userWallets)

        if let index = models.firstIndex(where: { $0.userWallet?.userWalletId == userWallet.userWalletId }) {
            models[index].setUserWallet(userWallet)
        } else {
            let newModel = CardViewModel(userWallet: userWallet)
            cardsRepository.add(newModel)
        }

        return true
    }

    func delete(_ userWallet: UserWallet) {
        let userWalletId = userWallet.userWalletId
        encryptionKeyByUserWalletId[userWalletId] = nil
        userWallets.removeAll { $0.userWalletId == userWalletId }
        cardsRepository.removeModel(withUserWalletId: userWalletId)

        encryptionKeyStorage.delete(userWallet)
        saveUserWallets(userWallets)
    }

    func clear() {
        let _ = saveUserWallets([])
        encryptionKeyByUserWalletId = [:]
        userWallets = []
        cardsRepository.clear()
        selectedUserWalletId = nil
        encryptionKeyStorage.clear()
    }

    private func savedUserWallets(withSensitiveData loadSensitiveData: Bool) -> [UserWallet] {
        do {
            guard fileManager.fileExists(atPath: userWalletListPath().path) else {
                return []
            }

            let decoder = JSONDecoder()

            let userWalletsPublicDataEncrypted = try Data(contentsOf: userWalletListPath())
            let userWalletsPublicData = try decrypt(userWalletsPublicDataEncrypted, with: publicDataEncryptionKey())
            var userWallets = try decoder.decode([UserWallet].self, from: userWalletsPublicData)

            if !loadSensitiveData {
                return userWallets
            }

            for i in 0 ..< userWallets.count {
                let userWallet = userWallets[i]

                let userWalletEncryptionKey: SymmetricKey

                if let encryptionKey = encryptionKeyByUserWalletId[userWallet.userWalletId] {
                    userWalletEncryptionKey = encryptionKey
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

            let userWalletsWithoutSensitiveInformation: [UserWallet] = userWallets.map {
                var card = $0.card
                card.wallets = []

                var userWalletWithoutKeys = $0
                userWalletWithoutKeys.card = card
                return userWalletWithoutKeys
            }

            let publicData = try encoder.encode(userWalletsWithoutSensitiveInformation)
            let publicDataEncoded = try encrypt(publicData, with: publicDataEncryptionKey())
            try publicDataEncoded.write(to: userWalletListPath(), options: .atomic)
            try excludeFromBackup(url: userWalletListPath())

            for userWallet in userWallets {
                guard let userWalletEncryptionKey = userWallet.encryptionKey else {
                    print("User wallet \(userWallet.card.cardId) failed to generate encryption key")
                    continue
                }

                let sensitiveInformation = UserWallet.SensitiveInformation(wallets: userWallet.card.wallets)
                let sensitiveDataEncoded = try encrypt(encoder.encode(sensitiveInformation), with: userWalletEncryptionKey)
                let sensitiveDataPath = userWalletPath(for: userWallet)
                try sensitiveDataEncoded.write(to: sensitiveDataPath, options: .atomic)
                try excludeFromBackup(url: sensitiveDataPath)
            }
        } catch {
            print("Failed to save user wallets", error)
        }
    }

    private func publicDataEncryptionKey() throws -> SymmetricKey {
        let keychainKey = "user_wallet_public_data_encryption_key"
        let secureStorage = SecureStorage()

        let encryptionKeyData = try secureStorage.get(keychainKey)
        if let encryptionKeyData = encryptionKeyData {
            let symmetricKey: SymmetricKey = .init(data: encryptionKeyData)
            return symmetricKey
        }

        let newEncryptionKey = SymmetricKey(size: .bits256)
        try secureStorage.store(newEncryptionKey.dataRepresentationWithHexConversion, forKey: keychainKey)
        return newEncryptionKey
    }

    private func userWalletListPath() -> URL {
        userWalletDirectoryUrl.appendingPathComponent("user_wallets.bin")
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
