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

class CommonUserWalletRepository: UserWalletRepository {
    @Injected(\.globalServicesContext) private var globalServicesContext: GlobalServicesContext
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    var isLocked: Bool {
        let hasUnlockedModels = models.contains(where: { !$0.isUserWalletLocked })
        return !hasUnlockedModels
    }

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
    private let encryptionKeyStorage = UserWalletEncryptionKeyStorage()
    private let userWalletDataStorage = UserWalletDataStorage()
    private let userWalletEncryptionKeyStorage = UserWalletEncryptionKeyStorage()
    private let accessCodeRepository = AccessCodeRepository()
    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()
    private var bag: Set<AnyCancellable> = .init()

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
        AppLogger.info(self)
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod) async throws -> UserWalletModel {
        switch method {
        case .biometrics(let context):
            let model = try handleUnlock(context: context)
            logSignIn(method: method)
            return model

        case .biometricsUserWallet(let userWalletId, let context):
            let model = try await handleUnlock(userWalletId: userWalletId, context: context)
            logSignIn(method: method)
            return model

        case .encryptionKey(let userWalletId, let encryptionKey):
            let model = try await handleUnlock(userWalletId: userWalletId, encryptionKey: encryptionKey)
            logSignIn(method: method)
            return model
        }
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

        models.append(userWalletModel)
        sendEvent(.inserted(userWalletId: userWalletModel.userWalletId))
        select(userWalletId: userWalletModel.userWalletId)
        save(userWalletModel: userWalletModel)
    }

    func savePublicData() {
        userWalletDataStorage.savePublicData(models.compactMap { $0.serializePublic() })
    }

    func save(userWalletModel: UserWalletModel) {
        savePublicData()

        if let encryptionKey = UserWalletEncryptionKey(config: userWalletModel.config) {
            savePrivateData(userWalletModel: userWalletModel, encryptionKey: encryptionKey)
            encryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: userWalletModel.userWalletId)
        }
    }

    /// Clean all biometric related data
    func onBiometricsChanged(enabled: Bool) {
        #warning("hot wallet sdk")
        if enabled {
            models.forEach { model in
                if let encryptionKey = UserWalletEncryptionKey(config: model.config) {
                    userWalletEncryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: model.userWalletId)
                }
            }
        } else {
            accessCodeRepository.clear()

            let allUserWalletIds = models.map { $0.userWalletId }
            userWalletEncryptionKeyStorage.clear(userWalletIds: allUserWalletIds)
            visaRefreshTokenRepository.clearPersistent()
        }
    }

    /// Clean all data except current user wallet
    func onSaveUserWalletsChanged(enabled: Bool) {
        #warning("hot wallet sdk")
        if enabled {
            savePublicData()

            if let selectedModel, let encryptionKey = UserWalletEncryptionKey(config: selectedModel.config) {
                savePrivateData(userWalletModel: selectedModel, encryptionKey: encryptionKey)
                encryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: selectedModel.userWalletId)
            }
        } else {
            let selectedModel = selectedModel

            accessCodeRepository.clear()
            visaRefreshTokenRepository.clearPersistent()
            let userWalletIds = models.map { $0.userWalletId }
            userWalletDataStorage.clear(userWalletIds: userWalletIds)
            encryptionKeyStorage.clear(userWalletIds: userWalletIds)

            if let selectedModel {
                models = [selectedModel]
            }

            let otherUserWallets = models.filter { $0.userWalletId != selectedUserWalletId }
            sendEvent(.deleted(userWalletIds: otherUserWallets.map { $0.userWalletId }))
        }
    }

    func lock() {
        guard !isLocked else {
            return
        }

        lockInternal()
    }

    func select(userWalletId: UserWalletId) {
        guard selectedUserWalletId != userWalletId,
              let model = models[userWalletId] else {
            return
        }

        selectedUserWalletId = model.userWalletId
        AppSettings.shared.selectedUserWalletId = model.userWalletId.value
        initializeServicesForSelectedModel()
        sendEvent(.selected(userWalletId: model.userWalletId))
    }

    /// Clean all data for specific user wallet
    func delete(userWalletId: UserWalletId) {
        guard let currentIndex = models.firstIndex(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        let nextSelectionIndex = currentIndex > 0 ? (currentIndex - 1) : 0

        userWalletDataStorage.delete(userWalletId: userWalletId, updatedWallets: models.compactMap { $0.serializePublic() })
        encryptionKeyStorage.clear(userWalletIds: [userWalletId])
        globalServicesContext.cleanServicesForWallet(userWalletId: userWalletId)

        let associatedCardIds = models[currentIndex].associatedCardIds
        try? accessCodeRepository.deleteAccessCode(for: Array(associatedCardIds))
        associatedCardIds.forEach {
            try? visaRefreshTokenRepository.deleteToken(cardId: $0)
        }

        models.removeAll { $0.userWalletId == userWalletId }

        #warning("delete specific mobile wallet")

        if models.isEmpty {
            AppSettings.shared.startWalletUsageDate = nil
            lockInternal()
        } else {
            sendEvent(.deleted(userWalletIds: [userWalletId]))
            let newModel = models[nextSelectionIndex]
            select(userWalletId: newModel.userWalletId)
        }
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

    private func logSignIn(method: UserWalletRepositoryUnlockMethod) {
        guard let selectedModel else {
            return
        }

        let walletHasBackup = Analytics.ParameterValue.affirmativeOrNegative(for: selectedModel.hasBackupCards)

        if AppSettings.shared.startWalletUsageDate == nil {
            AppSettings.shared.startWalletUsageDate = Date()
        }

        Analytics.log(event: .signedIn, params: [
            .signInType: method.analyticsValue.rawValue,
            .walletsCount: "\(models.count)",
            .walletHasBackup: walletHasBackup.rawValue,
        ])
    }

    private func handleUnlock(context: LAContext) throws -> UserWalletModel {
        let userWalletIds = models.map { $0.userWalletId }
        let encryptionKeys = try encryptionKeyStorage.fetch(userWalletIds: userWalletIds, context: context)
        let sensitiveInfos = userWalletDataStorage.fetchPrivateData(encryptionKeys: encryptionKeys)

        if sensitiveInfos.isEmpty {
            // clean to prevent double tap
            AccessCodeRepository().clear()
            throw UserWalletRepositoryError.biometricsChanged
        }

        let publicData = models.compactMap { $0.serializePublic() }
        let unlockedModels = publicData.map { userWalletStorageItem in
            if let sensitiveInfo = sensitiveInfos[UserWalletId(value: userWalletStorageItem.userWalletId)],
               let userWalletModel = CommonUserWalletModelFactory().makeModel(publicData: userWalletStorageItem, sensitiveData: sensitiveInfo) {
                return userWalletModel
            }

            return LockedUserWalletModel(with: userWalletStorageItem)
        }

        models = unlockedModels

        if selectedUserWalletId == nil {
            selectedUserWalletId = models.first.map { $0.userWalletId }
        }

        initializeServicesForSelectedModel()

        guard let selectedModel else {
            throw UserWalletRepositoryError.cantSelectWallet
        }

        sendEvent(.unlockedBiometrics)
        return selectedModel
    }

    private func handleUnlock(userWalletId: UserWalletId, context: LAContext) async throws -> UserWalletModel {
        let encryptionKeys = try encryptionKeyStorage.fetch(userWalletIds: [userWalletId], context: context)
        guard let sensitiveInfo = userWalletDataStorage.fetchPrivateData(encryptionKeys: encryptionKeys)[userWalletId] else {
            throw UserWalletRepositoryError.biometricsChanged
        }

        guard let existingLockedModel = models[userWalletId],
              let publicData = existingLockedModel.serializePublic(),
              let unlockedModel = CommonUserWalletModelFactory().makeModel(
                  publicData: publicData,
                  sensitiveData: sensitiveInfo
              ) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        models[userWalletId] = unlockedModel
        globalServicesContext.initializeServices(userWalletModel: unlockedModel)
        await unlockUnprotectedMobileWalletsIfNeeded()
        sendEvent(.unlocked(userWalletId: userWalletId))
        return unlockedModel
    }

    private func handleUnlock(userWalletId: UserWalletId, encryptionKey: UserWalletEncryptionKey) async throws -> UserWalletModel {
        guard let existingLockedModel = models[userWalletId] else {
            throw UserWalletRepositoryError.notFound
        }

        // We have to refresh a key on every unlock because we are unable to check presence of the key
        encryptionKeyStorage.refreshEncryptionKey(encryptionKey, for: userWalletId)

        guard let sensitiveInfo = userWalletDataStorage.fetchPrivateData(encryptionKeys: [userWalletId: encryptionKey])[userWalletId],
              let publicData = existingLockedModel.serializePublic(),
              let unlockedModel = CommonUserWalletModelFactory().makeModel(
                  publicData: publicData,
                  sensitiveData: sensitiveInfo
              ) else {
            throw UserWalletRepositoryError.cantUnlockWallet
        }

        models[userWalletId] = unlockedModel
        globalServicesContext.initializeServices(userWalletModel: unlockedModel)
        await unlockUnprotectedMobileWalletsIfNeeded()
        sendEvent(.unlocked(userWalletId: userWalletId))
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

    private func lockInternal() {
        let lockedModels = models.compactMap { model -> LockedUserWalletModel? in
            guard let serialized = model.serializePublic() else {
                return nil
            }

            return LockedUserWalletModel(with: serialized)
        }

        models = lockedModels
        globalServicesContext.resetServices()
        globalServicesContext.stopAnalyticsSession()
        sendEvent(.locked)
    }

    private func initializeServicesForSelectedModel() {
        globalServicesContext.resetServices()

        guard let selectedModel else { return }

        globalServicesContext.initializeServices(userWalletModel: selectedModel)
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
}
