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
    private var fetchPreferencesTask: Task<Void, Error>?
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
            .map { $0.remoteValueState(for: .transactionAlerts) }
            .removeDuplicates()
            .pairwise()
            .filter { previous, current in
                switch (previous, current) {
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

        notificationPreferencesProvider
            .remoteStatesPublisher
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                for channel in PushChannel.allCases {
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

    private func fetchNotificationPreferences() {
        fetchPreferencesTask?.cancel()

        fetchPreferencesTask = runTask(in: self) { manager in
            do {
                try await manager.notificationPreferencesProvider.fetchPreferences()
            } catch {
                // Provider publishes `.failed` on fetch error.
            }

            for channel in PushChannel.allCases {
                manager.updateStatusIfNeeded(for: channel)
            }
        }
    }
}

// MARK: - Helpers

private extension CommonUserWalletPushNotificationsManager {
    func definePushNotifyStatus(for channel: PushChannel) async -> UserWalletPushNotifyStatus {
        switch notificationPreferencesProvider.remoteStates.loadState {
        case .loading:
            return .loading
        case .failed:
            return .failed
        case .ready:
            guard await pushNotificationsPermission.isAuthorized else {
                return .needSystemPermission
            }

            let preference = notificationPreferencesProvider.remoteStates.preference(for: channel)
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

        updateTasks[channel] = runTask(in: self) { manager in
            do {
                try await manager.notificationPreferencesProvider.updatePreferences(isEnabled: value, for: channel)
            } catch {
                // Provider rolls back `remoteStates` and republishes on failure.
            }

            manager.updateStatusIfNeeded(for: channel)
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

    var isRemoteStatusEnabled: Bool {
        guard case .ready = notificationPreferencesProvider.remoteStates.loadState else {
            return false
        }

        return notificationPreferencesProvider.remoteStates.preference(for: .transactionAlerts).isEnabled
    }

    func process(_ event: UserWalletPushNotificationsEvent) {
        switch event {
        case .handleRemoteValue(let value, let channel):
            applyLocalStatusUpdate(value, for: channel)
        case .walletBindingWithApplicationSynchronized:
            fetchNotificationPreferences()
        case .walletsBindingInfoUnavailable:
            applySyncFailure()
        }
    }

    func tryUpdateEnableState(value: Bool) {}

    func shouldAllowanceRemoteNotifyStatus() async -> Bool {
        let isAuthorizedPushNotifications = await pushNotificationsPermission.isAuthorized
        let hasCompletedAllowanceOnboarding = await AppSettings.shared.allowanceUserWalletIdTransactionsPush
            .contains(userWalletId.stringValue)

        return isAuthorizedPushNotifications && !hasCompletedAllowanceOnboarding
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
        isRemoteStatusEnabled
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
