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
    private let remoteStatusSyncing: UserWalletPushNotificationsRemoteStatusSyncing
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
        remoteStatusSyncing: UserWalletPushNotificationsRemoteStatusSyncing,
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
                case .autoEnablePreferencesRequired:
                    manager.performAllowanceOnboardingIfNeeded()
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Helpers

private extension CommonUserWalletPushNotificationsManager {
    func syncRemoteStatus() {
        remoteStatusSyncing.syncRemoteStatus()
    }

    @discardableResult
    func fetchPreferences() -> Task<Void, Error> {
        preferencesWorkflowTask?.cancel()

        let task = runTask(in: self) { manager in
            try await manager.notificationPreferencesProvider.fetchPreferences()
        }

        preferencesWorkflowTask = task
        return task
    }

    func applySyncFailure() {
        notificationPreferencesProvider.updateRemoteEnabled(.failed, for: .transactionAlerts)
    }

    /// Whether the transaction-alerts channel is enabled on the backend. Gates whether token
    /// addresses are sent to the backend for transactional push re-subscription.
    var isTransactionAlertsEnabled: Bool {
        guard case .ready = notificationPreferencesProvider.preferences.state else {
            return false
        }

        return notificationPreferencesProvider.preferences.preference(for: .transactionAlerts).isEnabled
    }
}

// MARK: - UserWalletPushNotificationsManager

extension CommonUserWalletPushNotificationsManager: UserWalletPushNotificationsManager {
    var preferencesPublisher: AnyPublisher<RemotePushPreferences, Never> {
        notificationPreferencesProvider.preferencesPublisher
    }

    var preferences: RemotePushPreferences {
        notificationPreferencesProvider.preferences
    }

    func process(_ event: UserWalletPushNotificationsEvent) {
        switch event {
        case .walletApplicationBindingSynchronized:
            fetchPreferences()
        case .walletBindingInfoUnavailable:
            applySyncFailure()
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
}

// MARK: - UserTokenListExternalParametersProvider

extension CommonUserWalletPushNotificationsManager: UserTokenListExternalParametersProvider {
    func provideTokenListAddresses() -> [WalletModelId: [String]]? {
        let walletModels = AccountWalletModelsAggregator.walletModels(from: accountModelsManager)

        return UserTokenListExternalParametersHelper.provideTokenListAddresses(
            with: walletModels,
            shouldIncludeAddresses: isTransactionAlertsEnabled
        )
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
        guard await shouldRunAllowanceOnboarding() else {
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

    func shouldRunAllowanceOnboarding() async -> Bool {
        let isAuthorizedPushNotifications = await pushNotificationsPermission.isAuthorized
        let hasCompletedAllowanceOnboarding = await AppSettings.shared.allowanceUserWalletIdTransactionsPush
            .contains(userWalletId.stringValue)

        return isAuthorizedPushNotifications && !hasCompletedAllowanceOnboarding
    }

    @MainActor
    func updateAllowanceIfNeeded() {
        if !AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue) {
            AppSettings.shared.allowanceUserWalletIdTransactionsPush.append(userWalletId.stringValue)
        }
    }
}
