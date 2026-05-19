//
//  CommonUserTokensPushNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class CommonUserTokensPushNotificationsManager {
    // MARK: - Services

    @Injected(\.pushNotificationsPermission) var pushNotificationsPermission: PushNotificationsPermissionService

    // MARK: - Private Properties

    private let userWalletId: UserWalletId
    private let accountModelsManager: AccountModelsManager
    private let remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing
    private let updateTrigger: UserTokensPushNotificationsUpdateTrigger
    private let notificationPreferencesProvider: NotificationPreferencesProvider

    private let _userWalletPushStatusSubject: CurrentValueSubject<UserWalletPushNotifyStatus, Never> = .init(.loading)
    private let _userWalletPushRemoteStatusSubject: CurrentValueSubject<RemoteValueState<Bool>, Never> = .init(.loading)

    private var updateTask: Task<Void, Error>?
    private var bag: Set<AnyCancellable> = []

    // MARK: Init

    init(
        userWalletId: UserWalletId,
        accountModelsManager: AccountModelsManager,
        remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing,
        notificationPreferencesProvider: NotificationPreferencesProvider
    ) {
        self.userWalletId = userWalletId
        self.accountModelsManager = accountModelsManager
        self.remoteStatusSyncing = remoteStatusSyncing
        self.notificationPreferencesProvider = notificationPreferencesProvider
        updateTrigger = UserTokensPushNotificationsUpdateTrigger(accountModelsManager: accountModelsManager)

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        updateTrigger
            .eventsPublisher
            .withWeakCaptureOf(self)
            .sink { manager, event in
                switch event {
                case .syncRemoteStatusRequired:
                    manager.syncRemoteStatus()
                case .updateStatusRequired:
                    manager.updateStatusIfNeeded()
                }
            }
            .store(in: &bag)
    }

    private func syncRemoteStatus() {
        remoteStatusSyncing.syncRemoteStatus()
    }

    private func updateStatusIfNeeded() {
        updateTask?.cancel()

        updateTask = runTask { [weak self] in
            guard let self else {
                return
            }

            let currentPushNotifyStatus = await definePushNotifyStatus()

            // Checking the deduplication of a status update call
            if currentPushNotifyStatus != _userWalletPushStatusSubject.value {
                await updateWalletPushNotifyStatus(currentPushNotifyStatus)
            }
        }
    }
}

// MARK: - Helpers

private extension CommonUserTokensPushNotificationsManager {
    func definePushNotifyStatus() async -> UserWalletPushNotifyStatus {
        let isAuthorized = await pushNotificationsPermission.isAuthorized
        let currentRemoteStatus = _userWalletPushRemoteStatusSubject.value

        // If system permission is not granted
        guard isAuthorized else {
            return .needSystemPermission
        }

        // System permission is granted, check remote status
        switch currentRemoteStatus {
        case .loading:
            return .loading
        case .failed:
            return .failed
        case .ready(let isEnabled):
            return isEnabled ? .enabled : .disabledInApp
        }
    }

    private func shouldSyncRemoteStatus(
        currentStatus: UserWalletPushNotifyStatus,
        newStatus: UserWalletPushNotifyStatus,
    ) -> Bool {
        // Don't sync if still loading or failed
        guard newStatus != .loading, newStatus != .failed else {
            return false
        }

        guard currentStatus != .loading, currentStatus != .failed else {
            return false
        }

        return newStatus.isActive != currentStatus.isActive
    }

    private func updateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) async {
        let currentStatus = _userWalletPushStatusSubject.value

        // Only update the final status subject.
        // Remote status is managed separately:
        // - Event.didReceiveRemoteStatus: updates from backend
        // - Event.didChangeLocalStatus: updates from user intent
        _userWalletPushStatusSubject.send(status)

        if shouldSyncRemoteStatus(currentStatus: currentStatus, newStatus: status) {
            syncRemoteStatus()
        }

        await updateAllowanceIfNeeded()
    }
}

// MARK: - Event Handling

private extension CommonUserTokensPushNotificationsManager {
    func applyRemoteStatusUpdate(_ status: RemoteValueState<Bool>) {
        _userWalletPushRemoteStatusSubject.send(status)
        updateStatusIfNeeded()
    }

    func applyLocalStatusUpdate(_ value: Bool) {
        updateTask?.cancel()

        updateTask = runTask(in: self) { @MainActor manager in
            let isAuthorized = await manager.pushNotificationsPermission.isAuthorized

            // Only update remote status if system permissions are granted.
            // We shouldn't set remote = enabled if permissions are not granted.
            if isAuthorized {
                // Step 1: Update remote status based on user's intent.
                // This represents what the user wants on the backend.
                manager._userWalletPushRemoteStatusSubject.send(.ready(value))
            } else if !value {
                // If permissions are not granted but user wants to disable,
                // we can still update remote status to disabled.
                manager._userWalletPushRemoteStatusSubject.send(.ready(false))
            }
            // If permissions are not granted and user wants to enable,
            // we don't update remote status (it stays as is).

            // Step 2: Recalculate final status based on:
            // - System permissions
            // - Remote status
            let newStatus = await manager.definePushNotifyStatus()

            // Step 3: Update final status (doesn't touch remote status).
            await manager.updateWalletPushNotifyStatus(newStatus)
        }
    }

    func applySyncFailure() {
        runTask(in: self) { @MainActor manager in
            await manager.updateWalletPushNotifyStatus(.failed)
        }
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

    var isRemoteStatusEnabled: Bool {
        if case .ready(let isEnabled) = _userWalletPushRemoteStatusSubject.value {
            return isEnabled
        }

        return false
    }

    func process(_ event: UserWalletPushNotificationsEvent) {
        switch event {
        case .handleRemoteStatus(let state):
            applyRemoteStatusUpdate(state)
        case .handleUpdateStatus(let value):
            applyLocalStatusUpdate(value)
        case .walletBindingWithApplicationSynchronized:
            updateStatusIfNeeded()
        case .walletsBindingInfoUnavailable:
            applySyncFailure()
        }
    }

    func getInitialPushStatusWithAllowance() async -> Bool {
        let currentStatus = status
        let isAuthorizedPushNotifications = await pushNotificationsPermission.isAuthorized

        // For failed state, don't use allowance logic - return false to avoid sending incorrect status
        if currentStatus == .failed {
            return false
        }

        // Force enable Push Notifications if wallet did set status loading and Push Permission service has status isAuthorized
        if currentStatus == .loading, isAuthorizedPushNotifications {
            return allowancePushNotifyStatus()
        }

        // For other states, return isActive (true only for .enabled)
        return status.isActive
    }
}

// MARK: - UserTokenListExternalParametersProvider

extension CommonUserTokensPushNotificationsManager: UserTokenListExternalParametersProvider {
    func provideTokenListAddresses() -> [WalletModelId: [String]]? {
        let walletModels = AccountWalletModelsAggregator.walletModels(from: accountModelsManager)
        let tokenListNotifyStatusValue = provideTokenListNotifyStatusValue()

        return UserTokenListExternalParametersHelper.provideTokenListAddresses(
            with: walletModels,
            tokenListNotifyStatusValue: tokenListNotifyStatusValue
        )
    }

    func provideTokenListNotifyStatusValue() -> Bool {
        isRemoteStatusEnabled
    }
}

// MARK: - Allowance Implementation

private extension CommonUserTokensPushNotificationsManager {
    @MainActor
    private func updateAllowanceIfNeeded() {
        if !AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue) {
            AppSettings.shared.allowanceUserWalletIdTransactionsPush.append(userWalletId.stringValue)
        }
    }

    func permissionRequestInitialPushAllowance() {
        let allowanceValue = allowancePushNotifyStatus()
        applyLocalStatusUpdate(allowanceValue)
    }

    func allowancePushNotifyStatus() -> Bool {
        let currentRemoteStatus = isRemoteStatusEnabled

        let allowanceUserWalletIdTransactionsPush = AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue)

        if !allowanceUserWalletIdTransactionsPush {
            // We will force the update of the push stats on the backend, provided that the system permissions have been issued in definePushNotifyStatus
            return true
        }

        return currentRemoteStatus
    }
}
