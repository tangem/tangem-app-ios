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
        return models.first {
            $0.userWalletId == selectedUserWalletId
        }
    }

    var selectedUserWalletId: UserWalletId?

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private(set) var models = [UserWalletModel]()
    private let userWalletDataStorage = UserWalletDataStorage()
    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()
    private var bag: Set<AnyCancellable> = .init()

    init() {}

    deinit {
        AppLogger.debug(self)
    }

    func unlock(userWalletId: UserWalletId, method: UserWalletRepositoryUnlockMethod) throws {
        let unlocked = try unlock(with: method)

        if unlocked.userWalletId != userWalletId {
            switch method {
            case .biometrics:
                throw UserWalletRepositoryError.biometricsChanged
            case .card:
                throw UserWalletRepositoryError.cardWithWrongUserWalletIdScanned
            }
        }
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod) throws -> UserWalletModel {
        switch method {
        case .card(let cardInfo):
            let model = try handleUnlock(cardInfo: cardInfo)
            logSignIn(method: method)
            return model
        case .biometrics(let context):
            let model = try handleUnlock(context: context)
            logSignIn(method: method)
            return model
        }
    }

    func updateAssociatedCard(userWalletId: UserWalletId, cardId: String) {
        guard let existing = models.first(where: { $0.userWalletId == userWalletId }) else {
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
        savePrivateData(userWalletModel: userWalletModel)
    }

    func onSaveUserWalletsChanged(enabled: Bool) {
        if enabled {
            savePublicData()

            if let selectedModel {
                savePrivateData(userWalletModel: selectedModel)
            }
        } else {
            let selectedModel = selectedModel

            visaRefreshTokenRepository.clearPersistent()
            userWalletDataStorage.clear(userWalletIds: models.map { $0.userWalletId })

            let otherUserWallets = models.filter { $0.userWalletId != selectedUserWalletId }

            for model in otherUserWallets {
                model.cleanup()
            }

            if let selectedModel {
                models = [selectedModel]
            }

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
              let model = models.first(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        selectedUserWalletId = model.userWalletId
        AppSettings.shared.selectedUserWalletId = model.userWalletId.value
        initializeServicesForSelectedModel()
        sendEvent(.selected(userWalletId: model.userWalletId))
    }

    func delete(userWalletId: UserWalletId) {
        guard let currentIndex = models.firstIndex(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        let nextSelectionIndex = currentIndex > 0 ? (currentIndex - 1) : 0

        models[currentIndex].cleanup()

        models.removeAll { $0.userWalletId == userWalletId }
        userWalletDataStorage.delete(userWalletId: userWalletId, updatedWallets: models.compactMap { $0.serializePublic() })
        globalServicesContext.cleanServicesForWallet(userWalletId: userWalletId,)

        if models.isEmpty {
            AppSettings.shared.startWalletUsageDate = nil
            lockInternal()
        } else if !models.contains(where: { !$0.isUserWalletLocked }) {
            lockInternal()
        } else {
            sendEvent(.deleted(userWalletIds: [userWalletId]))
            let newModel = models[nextSelectionIndex]
            select(userWalletId: newModel.userWalletId)
        }
    }

    private func savePrivateData(userWalletModel: UserWalletModel) {
        if let encryptionKey = UserWalletEncryptionKey(config: userWalletModel.config),
           let sensitiveInfo = userWalletModel.serializePrivate() {
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
        let sensitiveInfos = userWalletDataStorage.fetchPrivateData(
            unlockMethod: .biometrics(context),
            userWalletIds: models.map { $0.userWalletId }
        )

        if sensitiveInfos.isEmpty {
            // clean to prevent double tap
            AccessCodeRepository().clear()
            throw UserWalletRepositoryError.biometricsChanged
        }

        // [REDACTED_TODO_COMMENT]
        let publicModels = models.compactMap { $0.serializePublic() }

        let unlockedModels = publicModels.map { userWalletStorageItem in
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

    private func handleUnlock(cardInfo: CardInfo) throws -> UserWalletModel {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)

        guard let userWalletId = UserWalletId(config: config),
              let encryptionKey = UserWalletEncryptionKey(config: config) else {
            throw UserWalletRepositoryError.cantUnlockWithCard
        }

        // We have to refresh a key on every scan because we are unable to check presence of the key
        UserWalletEncryptionKeyStorage().refreshEncryptionKey(encryptionKey, for: userWalletId)

        let sensitiveInfos = userWalletDataStorage.fetchPrivateData(
            unlockMethod: .userWallet(userWalletId: userWalletId, key: encryptionKey),
            userWalletIds: models.map { $0.userWalletId }
        )

        // unlock all locked and unprotected mobile wallets
        for sensitiveInfo in sensitiveInfos.filter({ $0.key != userWalletId }) {
            if let publicDataIndex = models.firstIndex(where: { $0.userWalletId == sensitiveInfo.key }),
               models[publicDataIndex].isUserWalletLocked,
               let publicData = models[publicDataIndex].serializePublic(),
               let unlockedModel = CommonUserWalletModelFactory().makeModel(publicData: publicData, sensitiveData: sensitiveInfo.value) {
                models[publicDataIndex] = unlockedModel
            }
        }

        if let sensitiveInfo = sensitiveInfos[userWalletId],
           let existingModelIndex = models.firstIndex(where: { $0.userWalletId == userWalletId }) {
            let existingLockedModel = models[existingModelIndex]

            if !existingLockedModel.isUserWalletLocked {
                throw UserWalletRepositoryError.duplicateWalletAdded
            }

            if let publicData = existingLockedModel.serializePublic(),
               let unlockedModel = CommonUserWalletModelFactory().makeModel(
                   publicData: publicData,
                   sensitiveData: sensitiveInfo
               ) {
                // unlock existing, exit
                models[existingModelIndex] = unlockedModel
                globalServicesContext.initializeServices(userWalletModel: unlockedModel)
                sendEvent(.unlocked(userWalletId: userWalletId))
                return unlockedModel
            }

            throw UserWalletRepositoryError.cantUnlockWithCard
        } else {
            // new card scanned, add it
            if let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                walletInfo: .cardWallet(cardInfo),
                keys: .cardWallet(keys: cardInfo.card.wallets)
            ) {
                try add(userWalletModel: newUserWalletModel)
                return newUserWalletModel
            } else {
                throw UserWalletRepositoryError.cantUnlockWithCard
            }
        }
    }

    private func lockInternal() {
        models = []
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

extension CommonUserWalletRepository {
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
}

private extension UserWalletModel {
    func serializePublic() -> StoredUserWallet? {
        (self as? UserWalletSerializable)?.serializePublic()
    }

    func serializePrivate() -> StoredUserWallet.SensitiveInfo? {
        (self as? UserWalletSerializable)?.serializePrivate()
    }
}
