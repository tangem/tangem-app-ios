//
//  UserWalletRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import LocalAuthentication
import Combine
import CryptoKit
import TangemSdk
import TangemVisa
import TangemLocalization
import TangemFoundation
import TangemMobileWalletSdk
import TangemPay

class CommonUserWalletRepository: UserWalletRepository {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository
    @Injected(\.tangemPayAuthorizationTokensRepository)
    private var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    var shouldLockOnBackground: Bool {
        if isLocked {
            return false
        }

        let hasProtected = models.contains(where: { !$0.isUnprotectedMobileWallet })

        return hasProtected
    }

    var isLocked: Bool { _locked }

    var selectedModel: UserWalletModel? {
        if let selectedUserWalletId {
            return models[selectedUserWalletId]
        }

        return nil
    }

    var selectedUserWalletId: UserWalletId?

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private(set) var models = [UserWalletModel]()
    private let userWalletDataStorage = UserWalletDataStorage()
    private let userWalletEncryptionKeyStorage = UserWalletEncryptionKeyStorage()
    private let accessCodeRepository = AccessCodeRepository()
    private let mobileWalletSdk = CommonMobileWalletSdk()
    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()
    private var bag: Set<AnyCancellable> = .init()
    private var _locked: Bool = true

    init() {}

    deinit {
        AppLogger.debug(self)
    }

    func initialize() async {
        let savedSelectedUserWalletId = await AppSettings.shared.selectedUserWalletId

        if !savedSelectedUserWalletId.isEmpty {
            selectedUserWalletId = UserWalletId(value: savedSelectedUserWalletId)
        }

        let savedUserWallets = userWalletDataStorage.fetchPublicData()
        let models = savedUserWallets.map { LockedUserWalletModel(with: $0) }
        self.models = models

        await unlockUnprotectedMobileWalletsIfNeeded()

        let allUnlocked = self.models.allConforms { !$0.isUserWalletLocked }
        if allUnlocked {
            unlockInternal()
        }

        AppLogger.info(self)
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod) async throws -> UserWalletModel {
        let unlockedModel: UserWalletModel

        switch method {
        case .biometrics(let context):
            unlockedModel = try handleUnlock(context: context)
        case .biometricsUserWallet(let userWalletId, let context):
            unlockedModel = try await handleUnlock(userWalletId: userWalletId, context: context)
        case .encryptionKey(let userWalletId, let encryptionKey):
            unlockedModel = try await handleUnlock(userWalletId: userWalletId, encryptionKey: encryptionKey)
        }

        unlockInternal()
        return unlockedModel
    }

    func updateAssociatedCard(userWalletId: UserWalletId, cardId: String) {
        guard let existing = models[userWalletId] else {
            return
        }

        existing.addAssociatedCard(cardId: cardId)
        savePublicData()
    }

    func add(userWalletModel: UserWalletModel) throws {
        guard !models.contains(where: { $0.userWalletId == userWalletModel.userWalletId }) else {
            throw UserWalletRepositoryError.duplicateWalletAdded
        }

        let shouldShowInsertedEvent = models.isNotEmpty
        models.append(userWalletModel)
        if shouldShowInsertedEvent {
            sendEvent(.inserted(userWalletId: userWalletModel.userWalletId))
        }

        select(userWalletId: userWalletModel.userWalletId)
        save(userWalletModel: userWalletModel)

        if isLocked {
            unlockInternal()
        }
    }

    func savePublicData() {
        userWalletDataStorage.savePublicData(models.compactMap { $0.serializePublic() })
    }

    func save(userWalletModel: UserWalletModel) {
        savePublicData()

        if let encryptionKey = UserWalletEncryptionKey(config: userWalletModel.config) {
            savePrivateData(userWalletModel: userWalletModel, encryptionKey: encryptionKey)
            userWalletEncryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: userWalletModel.userWalletId)
        }
    }

    /// Clean all biometric related data
    func onBiometricsChanged(enabled: Bool) {
        if enabled {
            models.forEach { model in
                if let encryptionKey = UserWalletEncryptionKey(config: model.config) {
                    userWalletEncryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: model.userWalletId)
                }
            }
            // Biometrics on protected mobile wallets could be enabled only after the user has unlocked the wallet via passcode
        } else {
            accessCodeRepository.clear()

            let allUserWalletIds = models.map { $0.userWalletId }
            userWalletEncryptionKeyStorage.clear(userWalletIds: allUserWalletIds)
            visaRefreshTokenRepository.clearPersistent()
            mobileWalletSdk.clearBiometrics(walletIDs: allUserWalletIds)
        }
    }

    /// Clean all data except current user wallet
    func onSaveUserWalletsChanged(enabled: Bool) {
        if enabled {
            savePublicData()

            if let selectedModel, let encryptionKey = UserWalletEncryptionKey(config: selectedModel.config) {
                savePrivateData(userWalletModel: selectedModel, encryptionKey: encryptionKey)
                userWalletEncryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: selectedModel.userWalletId)
            }

            // All the necessary data is already saved in MobileWalletSdk, so we don't need to do anything else.
        } else {
            let selectedModel = selectedModel

            accessCodeRepository.clear()
            visaRefreshTokenRepository.clearPersistent()
            let userWalletIds = models.map { $0.userWalletId }
            userWalletDataStorage.clear()
            userWalletEncryptionKeyStorage.clear(userWalletIds: userWalletIds)

            let modelsToDelete = userWalletIds.filter { $0 != selectedModel?.userWalletId }

            do {
                try mobileWalletSdk.delete(walletIDs: modelsToDelete)
            } catch {
                Log.error("Failed to delete mobile sdk data: \(error.localizedDescription)")
            }

            let otherUserWallets = models.filter { $0.userWalletId != selectedUserWalletId }

            if let selectedModel {
                models = [selectedModel]
            }

            sendEvent(.deleted(userWalletIds: otherUserWallets.map { $0.userWalletId }, isRepositoryEmpty: false))
        }
    }

    func lock() {
        guard !isLocked else {
            return
        }

        lockInternal()
    }

    func select(userWalletId: UserWalletId) {
        guard let model = models[userWalletId] else {
            return
        }

        selectedUserWalletId = model.userWalletId
        AppSettings.shared.selectedUserWalletId = model.userWalletId.value
        sendEvent(.selected(userWalletId: model.userWalletId))
    }

    /// Clean all data for specific user wallet
    func delete(userWalletId: UserWalletId) {
        guard let currentIndex = models.firstIndex(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        let nextSelectionIndex = currentIndex > 0 ? (currentIndex - 1) : 0

        userWalletEncryptionKeyStorage.clear(userWalletIds: [userWalletId])

        let associatedCardIds = models[currentIndex].associatedCardIds
        try? accessCodeRepository.deleteAccessCode(for: Array(associatedCardIds))
        associatedCardIds.forEach {
            try? visaRefreshTokenRepository.deleteToken(visaRefreshTokenId: .cardId($0))
        }
        try? tangemPayAuthorizationTokensRepository.deleteTokens(customerWalletId: userWalletId.stringValue)

        let removedModels = models.filter { $0.userWalletId == userWalletId }
        models.removeAll { $0.userWalletId == userWalletId }
        userWalletDataStorage.delete(userWalletId: userWalletId, updatedWallets: models.compactMap { $0.serializePublic() })

        try? mobileWalletSdk.delete(walletIDs: [userWalletId])

        sendEvent(.deleted(userWalletIds: [userWalletId], isRepositoryEmpty: models.isEmpty))

        if models.isEmpty {
            lockInternal()
        } else {
            let newModel = models[nextSelectionIndex]
            select(userWalletId: newModel.userWalletId)
        }

        removedModels.forEach { $0.dispose() }
    }

    private func savePrivateData(userWalletModel: UserWalletModel, encryptionKey: UserWalletEncryptionKey) {
        if let sensitiveInfo = userWalletModel.serializePrivate() {
            userWalletDataStorage.savePrivateData(
                sensitiveInfo: sensitiveInfo,
                userWalletId: userWalletModel.userWalletId,
                encryptionKey: encryptionKey
            )
        }
    }

    private func _handleUnlock(context: LAContext) throws {
        // `userWalletIds` is filtered to include only locked user wallets.
        // This is required for the case when biometrics have changed:
        // some wallets may be unprotected and should be ignored during unlock.
        // Otherwise, they would produce non-empty `sensitiveInfos` and prevent
        // the biometrics-changed error from being propagated.
        let userWalletIds = models.filter(\.isUserWalletLocked).map { $0.userWalletId }
        let encryptionKeys = try userWalletEncryptionKeyStorage.fetch(userWalletIds: userWalletIds, context: context)
        let sensitiveInfos = userWalletDataStorage.fetchPrivateData(encryptionKeys: encryptionKeys)

        if sensitiveInfos.isEmpty {
            // clean to prevent double tap
            AccessCodeRepository().clear()
            Analytics.log(.signInErrorBiometricUpdated, contextParams: .empty)
            throw UserWalletRepositoryError.biometricsChanged
        }

        let publicData = models.compactMap { $0.serializePublic() }
        let unlockedModels = publicData.map { userWalletStorageItem in
            let userWalletId = UserWalletId(value: userWalletStorageItem.userWalletId)

            // Already unlocked and unprotected mobile wallet
            if let userWalletModel = models[userWalletId], !userWalletModel.isUserWalletLocked {
                return userWalletModel
            }

            if let sensitiveInfo = sensitiveInfos[userWalletId],
               let userWalletModel = CommonUserWalletModelFactory().makeModel(publicData: userWalletStorageItem, sensitiveData: sensitiveInfo) {
                return userWalletModel
            }

            return LockedUserWalletModel(with: userWalletStorageItem)
        }

        models = unlockedModels
    }

    private func handleUnlock(context: LAContext) throws -> UserWalletModel {
        try _handleUnlock(context: context)

        guard let userWalletIdToSelect = selectedUserWalletId ?? models.first.map({ $0.userWalletId }) else {
            throw UserWalletRepositoryError.cantSelectWallet
        }

        select(userWalletId: userWalletIdToSelect)

        guard let selectedModel else {
            throw UserWalletRepositoryError.cantSelectWallet
        }

        return selectedModel
    }

    private func handleUnlock(userWalletId: UserWalletId, context: LAContext) async throws -> UserWalletModel {
        try _handleUnlock(context: context)

        guard let targetUnlockedModel = models[userWalletId] else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        guard !targetUnlockedModel.isUserWalletLocked else {
            Analytics.log(
                .signInErrorBiometricUpdated,
                contextParams: .custom(targetUnlockedModel.analyticsContextData)
            )
            throw UserWalletRepositoryError.biometricsChanged
        }

        sendEvent(.unlockedWallet(userWalletId: userWalletId))
        select(userWalletId: userWalletId)

        guard let selectedModel else {
            throw UserWalletRepositoryError.cantSelectWallet
        }

        return selectedModel
    }

    private func handleUnlock(userWalletId: UserWalletId, encryptionKey: UserWalletEncryptionKey) async throws -> UserWalletModel {
        guard let existingLockedModel = models[userWalletId] else {
            throw UserWalletRepositoryError.notFound
        }

        // We have to refresh a key on every unlock because we are unable to check presence of the key
        userWalletEncryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: userWalletId)

        guard let sensitiveInfo = userWalletDataStorage.fetchPrivateData(encryptionKeys: [userWalletId: encryptionKey])[userWalletId],
              let publicData = existingLockedModel.serializePublic(),
              let unlockedModel = CommonUserWalletModelFactory().makeModel(
                  publicData: publicData,
                  sensitiveData: sensitiveInfo
              ) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        models[userWalletId] = unlockedModel
        await unlockUnprotectedMobileWalletsIfNeeded()
        sendEvent(.unlockedWallet(userWalletId: userWalletId))
        return unlockedModel
    }

    private func unlockUnprotectedMobileWalletsIfNeeded() async {
        let lockedModels = models.filter { $0.isUserWalletLocked }
        let unlockers = lockedModels
            .map { UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: $0) }
            .filter { $0.canUnlockAutomatically }

        var encryptionKeys: [UserWalletId: UserWalletEncryptionKey] = [:]

        for unlocker in unlockers {
            let result = await unlocker.unlock()

            switch result {
            case .success(let userWalletId, let encryptionKey):
                encryptionKeys[userWalletId] = encryptionKey
                // We have to refresh a key on every unlock because we are unable to check presence of the key
                userWalletEncryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: userWalletId)
            default:
                continue
            }
        }

        let sensitiveInfos = userWalletDataStorage.fetchPrivateData(encryptionKeys: encryptionKeys)
        let publicData = lockedModels.compactMap { $0.serializePublic() }

        publicData.forEach { entry in
            let userWalletId = UserWalletId(value: entry.userWalletId)
            if let sensitiveInfo = sensitiveInfos[userWalletId],
               let unlockedModel = CommonUserWalletModelFactory().makeModel(publicData: entry, sensitiveData: sensitiveInfo) {
                models[userWalletId] = unlockedModel
            }
        }
    }

    private func unlockInternal() {
        _locked = false
        sendEvent(.unlocked)
    }

    private func lockInternal() {
        if AppSettings.shared.saveUserWallets {
            let processedModels = models.compactMap { model -> UserWalletModel? in
                if model.isUnprotectedMobileWallet {
                    return model
                }

                if let serialized = model.serializePublic() {
                    return LockedUserWalletModel(with: serialized)
                }

                return nil
            }

            models = processedModels
        } else {
            models = []
        }

        _locked = true
        sendEvent(.locked)
    }

    private func sendEvent(_ event: UserWalletRepositoryEvent) {
        eventSubject.send(event)
    }
}

private extension UserWalletModel {
    func serializePublic() -> StoredUserWallet? {
        (self as? UserWalletSerializable)?.serializePublic()
    }

    func serializePrivate() -> StoredUserWallet.SensitiveInfo? {
        (self as? UserWalletSerializable)?.serializePrivate()
    }

    var associatedCardIds: Set<String> {
        (self as? AssociatedCardIdsProvider)?.associatedCardIds ?? []
    }

    var isUnprotectedMobileWallet: Bool {
        let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: self)
        return unlocker.canUnlockAutomatically
    }
}
