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
    private let notificationPreferencesProvider: NotificationPreferencesProvider

    private lazy var updateTrigger: UserTokensPushNotificationsUpdateTrigger = .init(
        userWalletId: userWalletId,
        accountModelsManager: accountModelsManager,
        permissionService: pushNotificationsPermission
    )

    private let _userWalletPushStatusSubject: CurrentValueSubject<UserWalletPushNotifyStatus, Never> = .init(.loading)
    private let _userWalletPushRemoteStatusSubject: CurrentValueSubject<PushRemoteValueState<Bool>, Never> = .init(.loading)

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
                case .autoEnablePreferencesRequired:
                    break
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

        // If remote status is still loading (idle), return loading
        guard currentRemoteStatus != .loading else {
            return .loading
        }

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
    func applyRemoteStatusUpdate(_ value: Bool) {
        _userWalletPushRemoteStatusSubject.send(.ready(value))
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

    var preferencesPublisher: AnyPublisher<RemotePushPreferences, Never> {
        _userWalletPushRemoteStatusSubject
            .map { state -> RemotePushPreferences in
                switch state {
                case .loading:
                    return .loading
                case .failed:
                    return RemotePushPreferences(state: .failed)
                case .ready(let isEnabled):
                    var prefs = RemotePushPreferences(state: .ready([:]))
                    prefs.setEnabled(isEnabled, for: .transactionAlerts)
                    return prefs
                }
            }
            .eraseToAnyPublisher()
    }

    var isRemoteStatusEnabled: Bool {
        if case .ready(let isEnabled) = _userWalletPushRemoteStatusSubject.value {
            return isEnabled
        }

        return false
    }

    func process(_ event: UserWalletPushNotificationsEvent) {
        switch event {
        case .remoteStatusReceived(let value, _):
            applyRemoteStatusUpdate(value)
        case .walletApplicationBindingSynchronized:
            updateStatusIfNeeded()
        case .walletBindingInfoUnavailable:
            applySyncFailure()
        }
    }

    func tryUpdateEnableState(value: Bool, for channel: PushChannel) async throws {
        applyLocalStatusUpdate(value)
    }

    func shouldAllowanceRemoteNotifyStatus() async -> Bool {
        let isAuthorizedPushNotifications = await pushNotificationsPermission.isAuthorized
        let hasCompletedAllowanceOnboarding = await AppSettings.shared.allowanceUserWalletIdTransactionsPush
            .contains(userWalletId.stringValue)

        return isAuthorizedPushNotifications && !hasCompletedAllowanceOnboarding
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
}
