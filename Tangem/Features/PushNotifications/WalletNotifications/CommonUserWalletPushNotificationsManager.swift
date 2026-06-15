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

    private lazy var updateTrigger: UserWalletPushNotificationsUpdateTrigger = .init(
        userWalletId: userWalletId,
        accountModelsManager: accountModelsManager,
        permissionService: pushNotificationsPermission,
        notificationPreferencesProvider: notificationPreferencesProvider
    )

    private var preferencesWorkflowTask: Task<Void, Error>?
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
                    // [REDACTED_TODO_COMMENT]
                    break
                case .autoEnablePreferencesRequired:
                    manager.performAllowanceOnboardingIfNeeded()
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Helpers

private extension CommonUserWalletPushNotificationsManager {
    private func syncRemoteStatus() {
        remoteStatusSyncing.syncRemoteStatus()
    }

    @discardableResult
    private func fetchPreferences() -> Task<Void, Error> {
        preferencesWorkflowTask?.cancel()

        let task = runTask(in: self) { manager in
            try await manager.notificationPreferencesProvider.fetchPreferences()
        }

        preferencesWorkflowTask = task
        return task
    }
}

// MARK: - Event Handling

private extension CommonUserWalletPushNotificationsManager {
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
            fetchPreferences()
        case .walletBindingInfoUnavailable:
            applySyncFailure()
        case .remoteStatusReceived:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }

    func tryUpdateEnableState(value: Bool, for channel: PushChannel) async throws {
        try await notificationPreferencesProvider.updatePreferences(isEnabled: value, for: channel)
    }

    func refetchPreferences() async throws {
        // Route through `fetchPreferences()` so the retry shares the single-flight cancellation
        // with the `process(_:)`-driven fetch, then await the value to keep retries serialized
        // and surface failures to the caller.
        try await fetchPreferences().value
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

// MARK: - Allowance Onboarding

private extension CommonUserWalletPushNotificationsManager {
    func performAllowanceOnboardingIfNeeded() {
        preferencesWorkflowTask?.cancel()

        preferencesWorkflowTask = runTask(in: self) { manager in
            await manager.enableAllForOnboardingIfNeeded()
        }
    }

    func enableAllForOnboardingIfNeeded() async {
        guard await shouldAllowanceRemoteNotifyStatus() else {
            return
        }

        do {
            try await notificationPreferencesProvider.enableAll()
        } catch {
            // Provider rolls back and publishes the previous value on failure.
            return
        }

        await updateAllowanceIfNeeded()
    }

    @MainActor
    func updateAllowanceIfNeeded() {
        if !AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue) {
            AppSettings.shared.allowanceUserWalletIdTransactionsPush.append(userWalletId.stringValue)
        }
    }
}
