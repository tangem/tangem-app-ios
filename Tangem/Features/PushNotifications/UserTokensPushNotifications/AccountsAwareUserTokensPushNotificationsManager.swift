//
//  AccountsAwareUserTokensPushNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import Foundation
import Combine
import CombineExt
import TangemFoundation

// [REDACTED_TODO_COMMENT]
final class AccountsAwareUserTokensPushNotificationsManager {
    // MARK: - Services

    @Injected(\.userTokensPushNotificationsService) var userTokensPushNotificationsService: UserTokensPushNotificationsService
    @Injected(\.pushNotificationsPermission) var pushNotificationsPermission: PushNotificationsPermissionService
    @Injected(\.pushNotificationsInteractor) var pushNotificationsInteractor: PushNotificationsInteractor

    // MARK: - Private Properties

    private let userWalletId: UserWalletId
    private let accountModelsManager: AccountModelsManager
    private let remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing

    private let _userWalletPushStatusSubject: CurrentValueSubject<UserWalletPushNotifyStatus, Never> = .init(
        .unavailable(reason: .notInitialized, enabledRemote: false)
    )

    private var updateTask: Task<Void, Error>?
    private var bag: Set<AnyCancellable> = []

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
        accountModelsManager: AccountModelsManager,
        remoteStatusSyncing: UserTokensPushNotificationsRemoteStatusSyncing
    ) {
        self.userWalletId = userWalletId
        self.accountModelsManager = accountModelsManager
        self.remoteStatusSyncing = remoteStatusSyncing

        bind()
    }

    // MARK: - Private Implementation

    private func bind() {
        let isUserTokenListReadyPublisher = accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccountModels -> AnyPublisher<Bool, Never> in
                guard cryptoAccountModels.isNotEmpty else {
                    return .just(output: false)
                }

                return cryptoAccountModels
                    .map { $0.userTokensManager.userTokensPublisher }
                    .combineLatest()
                    .mapToValue(true)
                    .eraseToAnyPublisher()
            }
            .filter { $0 }
            .share(replay: 1)

        userTokensPushNotificationsService
            .entriesPublisher
            .removeDuplicates()
            .combineLatest(isUserTokenListReadyPublisher)
            .map(\.0)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { manager, entries in
                guard let entry = entries.first(where: { $0.id == manager.userWalletId.stringValue }) else {
                    return
                }

                manager.updateStatusIfNeeded(with: entry.notifyStatus)
            }
            .store(in: &bag)

        accountModelsManager
            .cryptoAccountModelsPublisher
            .flatMapLatest { cryptoAccountModels -> AnyPublisher<Bool, Never> in
                let hasPendingDerivationsPublishers = cryptoAccountModels
                    .compactMap { $0.userTokensManager.derivationManager?.hasPendingDerivations }

                guard hasPendingDerivationsPublishers.isNotEmpty else {
                    return .just(output: false)
                }

                return hasPendingDerivationsPublishers
                    .combineLatest()
                    .map { $0.contains(true) }
                    .eraseToAnyPublisher()
            }
            .pairwise()
            .filter { previous, current in
                // Proceed further only when pending derivations are finished
                return previous != current && current == false
            }
            .combineLatest(isUserTokenListReadyPublisher)
            .withWeakCaptureOf(self)
            .sink { manager, _ in
                manager.syncRemoteStatus()
            }
            .store(in: &bag)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .combineLatest(isUserTokenListReadyPublisher)
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { manager, _ in
                guard let currentEntry = manager.currentEntry else {
                    return
                }

                manager.updateStatusIfNeeded(with: currentEntry.notifyStatus)
            }
            .store(in: &bag)
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

extension AccountsAwareUserTokensPushNotificationsManager: UserTokensPushNotificationsManager {
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

extension AccountsAwareUserTokensPushNotificationsManager: UserTokenListExternalParametersProvider {
    func provideTokenListAddresses() -> [WalletModelId: [String]]? {
        let walletModels = AccountWalletModelsAggregator.walletModels(from: accountModelsManager)
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
