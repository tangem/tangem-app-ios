//
//  CommonUserTokensPushNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import Foundation
import Combine
import TangemFoundation

class CommonUserTokensPushNotificationsManager {
    // MARK: - Services

    @Injected(\.userTokensPushNotificationsService) var userTokensPushNotificationsService: UserTokensPushNotificationsService
    @Injected(\.pushNotificationsPermission) var pushNotificationsPermission: PushNotificationsPermissionService
    @Injected(\.pushNotificationsInteractor) var pushNotificationsInteractor: PushNotificationsInteractor

    // MARK: - Private Properties

    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?
    private let userTokenListManager: UserTokenListManager

    private let _userWalletPushStatusSubject: CurrentValueSubject<UserWalletPushNotifyStatus, Never> = .init(.unavailable(reason: .notInitialized, enabledRemote: false))

    private var allowanceTask: Task<Void, Error>?
    private var updateTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()

    private var isAvailableFeatureToggle: Bool {
        FeatureProvider.isAvailable(.pushTransactionNotifications)
    }

    private var currentEntry: ApplicationWalletEntry? {
        userTokensPushNotificationsService.entries.first(where: { $0.id == userWalletId.stringValue })
    }

    // MARK: Init

    init(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager,
        derivationManager: DerivationManager?,
        userTokenListManager: UserTokenListManager
    ) {
        self.userWalletId = userWalletId
        self.walletModelsManager = walletModelsManager
        self.derivationManager = derivationManager
        self.userTokenListManager = userTokenListManager

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        userTokensPushNotificationsService
            .entriesPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { manager, entries in
                // Need cancel update status when entries did update
                manager.updateTask?.cancel()

                guard let entry = entries.first(where: { $0.id == manager.userWalletId.stringValue }) else {
                    return
                }

                manager.updateStatusIfNeeded(with: entry.notifyStatus)
            }
            .store(in: &cancellables)

        derivationManager?
            .hasPendingDerivations
            .dropFirst() // We synchronize only state changes and send them only when they change.
            .removeDuplicates()
            .filter { !$0 }
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                manager.syncRemoteStatus()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                guard let currentEntry = manager.currentEntry else {
                    return
                }

                manager.updateStatusIfNeeded(with: currentEntry.notifyStatus)
            }
            .store(in: &cancellables)

        // It is used for existing versions in order to automatically show a notification to the user about transactions.
        pushNotificationsInteractor
            .permissionRequestPublisher
            .withWeakCaptureOf(self)
            .sink { manager, request in
                guard case .allow(.afterLogin) = request else {
                    return
                }

                // Need cancel allowance when permission did update
                manager.allowanceTask?.cancel()

                manager.checkAndUpdateInitialPushAllowanceForExistingWallet()
            }
            .store(in: &cancellables)
    }

    private func checkAndUpdateInitialPushAllowanceForExistingWallet() {
        allowanceTask = runTask(in: self) { @MainActor manager in
            let allowanceUserWalletIdTransactionsPush = AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(manager.userWalletId.stringValue)

            if !allowanceUserWalletIdTransactionsPush {
                AppSettings.shared.allowanceUserWalletIdTransactionsPush.append(manager.userWalletId.stringValue)

                // We will force the update of the push stats on the backend, provided that the system permissions have been issued in definePushNotifyStatus
                manager.updateStatusIfNeeded(with: true)
            }

            if let currentEntry = manager.currentEntry {
                manager.updateStatusIfNeeded(with: currentEntry.notifyStatus)
            }
        }
    }

    private func updateStatusIfNeeded(with remoteNotifyStatus: Bool) {
        updateTask = runTask { [weak self] in
            guard let self else {
                return
            }

            let pushNotifyStatus = await definePushNotifyStatus(with: remoteNotifyStatus)

            // Checking the deduplication of a status update call
            if pushNotifyStatus != _userWalletPushStatusSubject.value {
                updateWalletPushNotifyStatus(pushNotifyStatus)
            }
        }
    }

    private func definePushNotifyStatus(with remoteStatus: Bool) async -> UserWalletPushNotifyStatus {
        do {
            try await canEnablePushNotifyStatus()
            return remoteStatus ? .enabled : .disabled
        } catch {
            return .unavailable(reason: error, enabledRemote: remoteStatus)
        }
    }

    private func syncRemoteStatus() {
        userTokenListManager.upload()
    }
}

// MARK: - PushNotifyUserWalletStatusProvider

extension CommonUserTokensPushNotificationsManager: UserTokensPushNotificationsManager {
    var statusPublisher: AnyPublisher<UserWalletPushNotifyStatus, Never> {
        _userWalletPushStatusSubject.eraseToAnyPublisher()
    }

    var status: UserWalletPushNotifyStatus {
        _userWalletPushStatusSubject.value
    }

    func canEnablePushNotifyStatus() async throws(UserWalletPushNotifyStatus.UnavailableReason) {
        if await pushNotificationsPermission.isAuthorized {
            return
        }

        throw .permissionDenied
    }

    func updateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) {
        _userWalletPushStatusSubject.send(status)
        syncRemoteStatus()
        userTokensPushNotificationsService.updateWallet(notifyStatus: status.isActive, by: userWalletId.stringValue)
    }
}

// MARK: - UserTokenListExternalParametersProvider

extension CommonUserTokensPushNotificationsManager: UserTokenListExternalParametersProvider {
    func provideTokenListAddresses() -> [WalletModelId: [String]]? {
        guard let statusValue = provideTokenListNotifyStatusValue(), statusValue else {
            return nil
        }

        let walletModels = walletModelsManager.walletModels

        let result: [WalletModelId: [String]] = walletModels
            .reduce(into: [:]) { partialResult, walletModel in
                let addresses = walletModel.addresses.map(\.value)
                partialResult[walletModel.id] = addresses
            }

        return result
    }

    func provideTokenListNotifyStatusValue() -> Bool? {
        isAvailableFeatureToggle ? status.isActive : nil
    }
}
