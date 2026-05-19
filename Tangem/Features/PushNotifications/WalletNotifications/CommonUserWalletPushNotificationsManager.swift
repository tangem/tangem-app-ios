//
//  CommonUserWalletPushNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class CommonUserWalletPushNotificationsManager {
    // MARK: - Services

    @Injected(\.pushNotificationsPermission) var pushNotificationsPermission: PushNotificationsPermissionService

    // MARK: - Private Properties

    private let userWalletId: UserWalletId
    private let accountModelsManager: AccountModelsManager
    private let remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing
    private let notificationPreferencesProvider: NotificationPreferencesProvider
    private let updateTrigger: UserTokensPushNotificationsUpdateTrigger

    private let _userWalletPushStatusSubject: CurrentValueSubject<[PushChannel: UserWalletPushNotifyStatus], Never> = .init([:])

    private var updateTasks: [PushChannel: Task<Void, Error>] = [:]
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
                    for channel in PushChannel.allCases {
                        manager.updateStatusIfNeeded(for: channel)
                    }
                }
            }
            .store(in: &bag)

        // Backend transactional-push address sync when the settled remote toggle changes.
        notificationPreferencesProvider
            .remoteStatesPublisher
            .map { $0[.transactionAlerts] }
            .removeDuplicates()
            .pairwise()
            .filter { previous, current in
                switch (previous, current) {
                case (.pending(let previousPreference), .ready(let currentPreference)):
                    // Settled after a successful PUT; skip rollback (pending/ready values differ).
                    return previousPreference.isEnabled == currentPreference.isEnabled
                case (.ready(let previousPreference), .ready(let currentPreference)):
                    return previousPreference.isEnabled != currentPreference.isEnabled
                default:
                    return false
                }
            }
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                manager.syncRemoteStatus()
            }
            .store(in: &bag)

        // Subscribe to remoteStatesPublisher and update status only for channels present in remoteStates
        notificationPreferencesProvider
            .remoteStatesPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { manager, remoteStates in
                for channel in remoteStates.states.keys {
                    manager.updateStatusIfNeeded(for: channel)
                }
            }
            .store(in: &bag)
    }

    private func updateStatusIfNeeded(for channel: PushChannel) {
        updateTasks[channel]?.cancel()

        updateTasks[channel] = runTask { [weak self] in
            guard let self else {
                return
            }

            let currentPushNotifyStatus = await definePushNotifyStatus(for: channel)
            let previousChannelStatus = _userWalletPushStatusSubject.value[channel] ?? .loading

            // Checking the deduplication of a status update call
            if currentPushNotifyStatus != previousChannelStatus {
                await updateWalletPushNotifyStatus(currentPushNotifyStatus, for: channel)
            }
        }
    }
}

// MARK: - Helpers

private extension CommonUserWalletPushNotificationsManager {
    func definePushNotifyStatus(for channel: PushChannel) async -> UserWalletPushNotifyStatus {
        let isAuthorized = await pushNotificationsPermission.isAuthorized
        let currentRemoteStatus = notificationPreferencesProvider.remoteStates[channel]

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
        case .ready(let preference), .pending(let preference):
            return preference.isEnabled ? .enabled : .disabledInApp
        }
    }

    private func updateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus, for channel: PushChannel) async {
        var toUpdateStatus = _userWalletPushStatusSubject.value

        // Only update the final status subject.
        // Remote status is managed separately:
        // - Event.didReceiveRemoteStatus: updates from backend
        // - Event.didChangeLocalStatus: updates from user intent
        toUpdateStatus[channel] = status
        _userWalletPushStatusSubject.send(toUpdateStatus)

        await updateAllowanceIfNeeded()
    }

    private func syncRemoteStatus() {
        remoteStatusSyncing.syncRemoteStatus()
    }
}

// MARK: - Event Handling

private extension CommonUserWalletPushNotificationsManager {
    func applyLocalStatusUpdate(_ value: Bool, for channel: PushChannel) {
        updateTasks[channel]?.cancel()

        updateTasks[channel] = runTask(in: self) { @MainActor manager in
            let isAuthorized = await manager.pushNotificationsPermission.isAuthorized

            // Only update remote status if system permissions are granted.
            // We shouldn't set remote = enabled if permissions are not granted.
            if isAuthorized {
                manager.notificationPreferencesProvider.updatePreferences([(channel: channel, isEnabled: value)])
            } else if !value {
                // If permissions are not granted but user wants to disable,
                // we can still update remote status to disabled.
                manager.notificationPreferencesProvider.updatePreferences([(channel: channel, isEnabled: false)])
            }
        }
    }

    func applySyncFailure() {
        runTask(in: self) { @MainActor manager in
            for channel in PushChannel.allCases {
                await manager.updateWalletPushNotifyStatus(.failed, for: channel)
            }
        }
    }
}

// MARK: - PushNotifyUserWalletStatusProvider

extension CommonUserWalletPushNotificationsManager: UserTokensPushNotificationsManager {
    var statusPublisher: AnyPublisher<UserWalletPushNotifyStatus, Never> {
        _userWalletPushStatusSubject
            .map { $0[.transactionAlerts] ?? .loading }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var status: UserWalletPushNotifyStatus {
        _userWalletPushStatusSubject.value[.transactionAlerts] ?? .loading
    }

    func dispatch(_ event: UserTokensPushEvent) {
        switch event {
        case .didChangeLocalStatus(let value, let channel):
            applyLocalStatusUpdate(value, for: channel)
        case .walletBindingWithApplicationSynchronized:
            notificationPreferencesProvider.fetchPreferences()
        case .walletsBindingInfoUnavailable:
            applySyncFailure()
        case .didReceiveRemoteStatus:
            // [REDACTED_TODO_COMMENT]
            break
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

    var shouldShowPermissionWarning: Bool {
        // Warning is relevant only when push notifications are switched on remotely
        // but the user has revoked (or never granted) the iOS system permission.
        status == .needSystemPermission
    }
}

// MARK: - UserTokenListExternalParametersProvider

extension CommonUserWalletPushNotificationsManager: UserTokenListExternalParametersProvider {
    func provideTokenListAddresses() -> [WalletModelId: [String]]? {
        let walletModels = AccountWalletModelsAggregator.walletModels(from: accountModelsManager)
        let tokenListNotifyStatusValue = provideTokenListNotifyStatusValue()

        return UserTokenListExternalParametersHelper.provideTokenListAddresses(
            with: walletModels,
            tokenListNotifyStatusValue: tokenListNotifyStatusValue
        )
    }

    func provideTokenListNotifyStatusValue() -> Bool {
        notificationPreferencesProvider.remoteStates.preference(for: .transactionAlerts).isEnabled
    }
}

// MARK: - Allowance Implementation

private extension CommonUserWalletPushNotificationsManager {
    @MainActor
    private func updateAllowanceIfNeeded() {
        if !AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue) {
            AppSettings.shared.allowanceUserWalletIdTransactionsPush.append(userWalletId.stringValue)
        }
    }

    func permissionRequestInitialPushAllowance() {
        let toUpdateNotifyStatus = allowancePushNotifyStatus()
        applyLocalStatusUpdate(toUpdateNotifyStatus, for: .transactionAlerts)
    }

    func allowancePushNotifyStatus() -> Bool {
        let currentRemoteStatus = notificationPreferencesProvider
            .remoteStates
            .preference(for: .transactionAlerts)
            .isEnabled

        let allowanceUserWalletIdTransactionsPush = AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue)

        if !allowanceUserWalletIdTransactionsPush {
            // We will force the update of the push stats on the backend, provided that the system permissions have been issued in definePushNotifyStatus
            return true
        }

        return currentRemoteStatus
    }
}
