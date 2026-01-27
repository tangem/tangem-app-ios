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

@available(iOS, deprecated: 100000.0, message: "Will be removed after accounts migration is complete ([REDACTED_INFO])")
final class CommonUserTokensPushNotificationsManager {
    // MARK: - Services

    @Injected(\.userTokensPushNotificationsService) var userTokensPushNotificationsService: UserTokensPushNotificationsService
    @Injected(\.pushNotificationsPermission) var pushNotificationsPermission: PushNotificationsPermissionService
    @Injected(\.pushNotificationsInteractor) var pushNotificationsInteractor: PushNotificationsInteractor

    // MARK: - Private Properties

    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager
    private let userTokensManager: UserTokensManager
    private let remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing
    private let derivationManager: DerivationManager?

    private let _userWalletPushStatusSubject: CurrentValueSubject<UserWalletPushNotifyStatus, Never> = .init(
        .unavailable(reason: .notInitialized, enabledRemote: false)
    )

    private var updateTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()

    private var currentEntry: ApplicationWalletEntry? {
        userTokensPushNotificationsService.entries.first(where: { $0.id == userWalletId.stringValue })
    }

    @MainActor
    private var allowanceUserWalletIdTransactionsPush: Bool {
        AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue)
    }

    // MARK: Init

    init(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing,
        derivationManager: DerivationManager?,
    ) {
        self.userWalletId = userWalletId
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.remoteStatusSyncing = remoteStatusSyncing
        self.derivationManager = derivationManager

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        let readyUserTokenListPublisher = userTokensManager
            .userTokensPublisher
            .dropFirst()

        userTokensPushNotificationsService
            .entriesPublisher
            .removeDuplicates()
            .combineLatest(readyUserTokenListPublisher)
            .map(\.0)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { manager, entries in
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
            .combineLatest(readyUserTokenListPublisher)
            .filter { !$0.0 }
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                manager.syncRemoteStatus()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .combineLatest(readyUserTokenListPublisher)
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { manager, _ in
                guard let currentEntry = manager.currentEntry else {
                    return
                }

                manager.updateStatusIfNeeded(with: currentEntry.notifyStatus)
            }
            .store(in: &cancellables)
    }

    private func updateStatusIfNeeded(with remoteNotifyStatus: Bool) {
        // Need cancel update status when entries did update
        updateTask?.cancel()

        updateTask = runTask { [weak self] in
            guard let self else {
                return
            }

            let pushNotifyStatus = await definePushNotifyStatus(with: remoteNotifyStatus)

            // Checking the deduplication of a status update call
            if pushNotifyStatus != _userWalletPushStatusSubject.value {
                await updateWalletPushNotifyStatus(pushNotifyStatus)
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
        remoteStatusSyncing.syncRemoteStatus()
    }

    @MainActor
    private func updateAllowanceIfNeeded() {
        if !AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue) {
            AppSettings.shared.allowanceUserWalletIdTransactionsPush.append(userWalletId.stringValue)
        }
    }

    private func shouldSyncRemoteStatus(
        currentStatus: UserWalletPushNotifyStatus,
        newStatus: UserWalletPushNotifyStatus,
        hasAllowance: Bool
    ) -> Bool {
        currentStatus.isNotInitialized ? !hasAllowance : currentStatus.isActive != newStatus.isActive
    }

    private func updateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) async {
        let currentStatus = _userWalletPushStatusSubject.value

        _userWalletPushStatusSubject.send(status)

        if await shouldSyncRemoteStatus(
            currentStatus: currentStatus,
            newStatus: status,
            hasAllowance: allowanceUserWalletIdTransactionsPush
        ) {
            syncRemoteStatus()
        }

        userTokensPushNotificationsService.updateWallet(notifyStatus: status.isActive, by: userWalletId.stringValue)

        await updateAllowanceIfNeeded()
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

    func handleUpdateWalletPushNotifyStatus(_ status: UserWalletPushNotifyStatus) {
        runTask(in: self) { @MainActor manager in
            manager.updateTask?.cancel()
            await manager.updateWalletPushNotifyStatus(status)
        }
    }
}

// MARK: - UserTokenListExternalParametersProvider

extension CommonUserTokensPushNotificationsManager: UserTokenListExternalParametersProvider {
    func provideTokenListAddresses() -> [WalletModelId: [String]]? {
        let walletModels = walletModelsManager.walletModels
        let tokenListNotifyStatusValue = provideTokenListNotifyStatusValue()

        return UserTokenListExternalParametersHelper.provideTokenListAddresses(
            with: walletModels,
            tokenListNotifyStatusValue: tokenListNotifyStatusValue
        )
    }

    func provideTokenListNotifyStatusValue() -> Bool {
        UserTokenListExternalParametersHelper.provideTokenListNotifyStatusValue(with: self)
    }
}
