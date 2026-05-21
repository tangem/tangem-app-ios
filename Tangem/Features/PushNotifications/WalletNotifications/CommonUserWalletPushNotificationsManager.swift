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
    private lazy var updateTrigger: UserTokensPushNotificationsUpdateTrigger = .init(
        accountModelsManager: accountModelsManager,
        notificationPreferencesProvider: notificationPreferencesProvider,
        permissionService: pushNotificationsPermission
    )

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
                    manager.fetchNotificationPreferences()
                }
            }
            .store(in: &bag)
    }

    private func fetchNotificationPreferences() {
        fetchPreferencesTask?.cancel()

        fetchPreferencesTask = runTask(in: self) { manager in
            do {
                try await manager.notificationPreferencesProvider.fetchPreferences()
            } catch {
                // Provider publishes `.failed` on fetch error.
            }
        }
    }
}

// MARK: - Helpers

private extension CommonUserWalletPushNotificationsManager {
    private func syncRemoteStatus() {
        remoteStatusSyncing.syncRemoteStatus()
    }
}

// MARK: - Event Handling

private extension CommonUserWalletPushNotificationsManager {
    func applyRemoteStatusUpdate(_ value: Bool, for channel: PushChannel) {
        notificationPreferencesProvider.updateRemoteEnabled(.ready(value), for: channel)
    }

    func applySyncFailure() {
        notificationPreferencesProvider.updateRemoteEnabled(.failed, for: .transactionAlerts)
    }
}

// MARK: - PushNotifyUserWalletStatusProvider

extension CommonUserWalletPushNotificationsManager: UserTokensPushNotificationsManager {
    var statusPublisher: AnyPublisher<UserWalletPushNotifyStatus, Never> {
        notificationPreferencesProvider.preferencesPublisher
            .map { preferences -> UserWalletPushNotifyStatus in
                switch preferences.remoteValueState(for: .transactionAlerts) {
                case .loading: return .loading
                case .failed: return .failed
                case .ready(let preference): return preference.isEnabled ? .enabled : .disabledInApp
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var status: UserWalletPushNotifyStatus {
        switch notificationPreferencesProvider.preferences.remoteValueState(for: .transactionAlerts) {
        case .loading: return .loading
        case .failed: return .failed
        case .ready(let preference): return preference.isEnabled ? .enabled : .disabledInApp
        }
    }

    var preferencesPublisher: AnyPublisher<RemotePushPreferences, Never> {
        notificationPreferencesProvider.preferencesPublisher
    }

    var isRemoteStatusEnabled: Bool {
        guard case .ready = notificationPreferencesProvider.preferences.state else {
            return false
        }

        return notificationPreferencesProvider.preferences.preference(for: .transactionAlerts).isEnabled
    }

    func process(_ event: UserWalletPushNotificationsEvent) {
        switch event {
        case .walletApplicationBindingSynchronized:
            fetchNotificationPreferences()
        case .walletBindingInfoUnavailable:
            applySyncFailure()
        case .remoteStatusReceived(let value, let channel):
            // [REDACTED_TODO_COMMENT]
            break
        }
    }

    func tryUpdateEnableState(value: Bool, for channel: PushChannel) async throws {
        try await notificationPreferencesProvider.updatePreferences(isEnabled: value, for: channel)
    }

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
}
