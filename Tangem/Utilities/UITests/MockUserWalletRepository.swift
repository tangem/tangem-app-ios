//
//  MockUserWalletRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation
import Combine
import LocalAuthentication
import TangemFoundation
import TangemMobileWalletSdk

/// Mock implementation of UserWalletRepository for UI testing
/// Supports all protocol methods and allows pre-populating with wallet models
final class MockUserWalletRepository: UserWalletRepository {
    var shouldLockOnBackground: Bool {
        if isLocked {
            return false
        }
        // Check if any model requires protection (not automatically unlockable)
        let hasProtected = models.contains { model in
            let unlocker = UserWalletModelUnlockerFactory.makeUnlocker(userWalletModel: model)
            return !unlocker.canUnlockAutomatically
        }
        return hasProtected
    }

    var isLocked: Bool {
        _locked
    }

    private(set) var models: [UserWalletModel] = []

    var selectedModel: UserWalletModel? {
        guard let selectedUserWalletId else {
            return nil
        }
        return models.first(where: { $0.userWalletId == selectedUserWalletId })
    }

    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    private var selectedUserWalletId: UserWalletId?
    private var _locked: Bool = false
    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()
    private var unlockedModels: [UserWalletId: UserWalletModel] = [:]
    private let mnemonics: [String]

    init(mnemonics: [String]) {
        self.mnemonics = mnemonics
    }

    func initialize() async {
        AppSettings.shared.marketsTooltipWasShown = true

        guard !mnemonics.isEmpty, models.isEmpty else { return }

        for mnemonic in mnemonics {
            do {
                let wallet = try await MockWalletInitializer.createMockHotWallet(
                    mnemonic: mnemonic)
                await registerWallet(wallet)
            } catch {
                AppLogger.error("Failed to create mock hot wallet", error: error)
            }
        }
    }

    private func registerWallet(_ wallet: UserWalletModel) async {
        await verifyEncryptionKeysWithRetry(
            walletId: wallet.userWalletId, maxRetries: 5, delaySeconds: 0.3
        )

        unlockedModels[wallet.userWalletId] = wallet

        let storedWallet = createStoredUserWallet(from: wallet)
        let lockedWallet = LockedUserWalletModel(with: storedWallet)

        do {
            try add(userWalletModel: lockedWallet)
        } catch {
            AppLogger.error("Failed to add wallet to repository", error: error)
        }
    }

    func waitForWalletsCreation() {
        guard !mnemonics.isEmpty, models.isEmpty else { return }

        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await initialize()

            for (_, model) in unlockedModels {
                if let commonWalletModel = model as? CommonUserWalletModel {
                    await waitForWalletModelsInitialization(
                        walletModel: commonWalletModel, timeout: 10.0
                    )
                }
            }

            semaphore.signal()
        }
        semaphore.wait()
    }

    private func verifyEncryptionKeysWithRetry(
        walletId: UserWalletId, maxRetries: Int, delaySeconds: Double
    ) async {
        let sdk = CommonMobileWalletSdk()

        for attempt in 1 ... maxRetries {
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))

            do {
                let _ = try sdk.validate(auth: .none, for: walletId)
                return
            } catch {
                if attempt == maxRetries {
                    AppLogger.error(
                        "Failed to verify encryption keys after \(maxRetries) attempts",
                        error: error
                    )
                }
            }
        }
    }

    private func waitForWalletModelsInitialization(
        walletModel: CommonUserWalletModel, timeout: TimeInterval
    ) async {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            let isInitialized = walletModel.walletModelsManager.isInitialized

            if isInitialized {
                let hasValidAddresses = walletModel.walletModelsManager.walletModels.contains {
                    !$0.addresses.isEmpty && $0.addresses.contains { !$0.value.isEmpty }
                }

                if hasValidAddresses {
                    return
                }
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        AppLogger.warning("WalletModelsManager initialization timeout after \(timeout)s")
    }

    func lock() {
        guard !isLocked else {
            return
        }
        _locked = true
        sendEvent(.locked)
    }

    func unlock(with method: UserWalletRepositoryUnlockMethod) async throws -> UserWalletModel {
        let userWalletId: UserWalletId

        switch method {
        case .biometrics:
            if let selectedId = selectedUserWalletId {
                userWalletId = selectedId
            } else if let firstModel = models.first {
                userWalletId = firstModel.userWalletId
            } else {
                throw UserWalletRepositoryError.cantUnlockWallet
            }
        case .biometricsUserWallet(let walletId, _):
            userWalletId = walletId
        case .encryptionKey(let walletId, _):
            userWalletId = walletId
        }

        guard let model = models.first(where: { $0.userWalletId == userWalletId }) else {
            throw UserWalletRepositoryError.notFound
        }

        let unlockedModel: UserWalletModel
        if model.isUserWalletLocked, let originalModel = unlockedModels[userWalletId] {
            if let index = models.firstIndex(where: { $0.userWalletId == userWalletId }) {
                models[index] = originalModel
            }
            unlockedModel = originalModel
        } else {
            unlockedModel = model
        }

        _locked = false
        selectedUserWalletId = userWalletId
        sendEvent(.unlocked)
        sendEvent(.unlockedWallet(userWalletId: userWalletId))

        return unlockedModel
    }

    func select(userWalletId: UserWalletId) {
        guard models.contains(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        selectedUserWalletId = userWalletId
        sendEvent(.selected(userWalletId: userWalletId))
    }

    func updateAssociatedCard(userWalletId: UserWalletId, cardId: String) {
        // Mock implementation - no actual update needed
        // In real implementation, this would update the associated card ID
    }

    func add(userWalletModel: UserWalletModel) throws {
        guard !models.contains(where: { $0.userWalletId == userWalletModel.userWalletId })
        else {
            throw UserWalletRepositoryError.duplicateWalletAdded
        }

        models.append(userWalletModel)
        sendEvent(.inserted(userWalletId: userWalletModel.userWalletId))

        if !userWalletModel.isUserWalletLocked {
            select(userWalletId: userWalletModel.userWalletId)
        }

        if isLocked {
            _locked = false
            sendEvent(.unlocked)
        }
    }

    func delete(userWalletId: UserWalletId) {
        guard let index = models.firstIndex(where: { $0.userWalletId == userWalletId }) else {
            return
        }

        models.remove(at: index)
        sendEvent(.deleted(userWalletIds: [userWalletId]))

        if models.isEmpty {
            selectedUserWalletId = nil
            _locked = true
            sendEvent(.locked)
        } else {
            // Select the first remaining model if the deleted one was selected
            if selectedUserWalletId == userWalletId {
                selectedUserWalletId = models.first?.userWalletId
                if let newSelectedId = selectedUserWalletId {
                    sendEvent(.selected(userWalletId: newSelectedId))
                }
            }
        }
    }

    func onBiometricsChanged(enabled: Bool) {}

    func onSaveUserWalletsChanged(enabled: Bool) {}

    func savePublicData() {}

    func save(userWalletModel: UserWalletModel) {}

    private func sendEvent(_ event: UserWalletRepositoryEvent) {
        eventSubject.send(event)
    }

    private func createStoredUserWallet(from wallet: UserWalletModel) -> StoredUserWallet {
        if let serializable = wallet as? UserWalletSerializable {
            return serializable.serializePublic()
        }

        let name = wallet.name.isEmpty ? wallet.config.defaultName : wallet.name
        let mobileWalletInfo = MobileWalletInfo(
            hasMnemonicBackup: false,
            hasICloudBackup: false,
            accessCodeStatus: .none,
            keys: []
        )

        return StoredUserWallet(
            userWalletId: wallet.userWalletId.value,
            name: name,
            walletInfo: .mobileWallet(mobileWalletInfo)
        )
    }
}
#endif
