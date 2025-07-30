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

    // MARK: - Private Properties

    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager
    private let derivationManager: DerivationManager?
    private let userTokenListManager: UserTokenListManager

    private let _userWalletPushStatusSubject: CurrentValueSubject<UserWalletPushNotifyStatus, Never> = .init(.unavailable(reason: .notInitialized, enabledRemote: false))

    private var taskCancellable: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()

    private var isAvailableFeatureToggle: Bool {
        FeatureProvider.isAvailable(.pushTransactionNotifications)
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
                manager.taskCancellable?.cancel()

                guard let entry = entries.first(where: { $0.id == manager.userWalletId.stringValue }) else {
                    return
                }

                manager.updateStatusIfNeeded(by: entry)
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
                guard let entry = manager.userTokensPushNotificationsService.entries.first(where: {
                    $0.id == manager.userWalletId.stringValue
                }) else {
                    return
                }

                manager.updateStatusIfNeeded(by: entry)
            }
            .store(in: &cancellables)
    }

    private func definePushNotifyStatus(with remoteStatus: Bool) async -> UserWalletPushNotifyStatus {
        do {
            try await canEnablePushNotifyStatus()
            return remoteStatus ? .enabled : .disabled
        } catch {
            return .unavailable(reason: error, enabledRemote: remoteStatus)
        }
    }

    private func updateStatusIfNeeded(by entry: ApplicationWalletEntry) {
        taskCancellable = runTask { [weak self] in
            guard let self else {
                return
            }

            let pushNotifyStatus = await definePushNotifyStatus(with: entry.notifyStatus)

            // Just updating the status, as everything you need came from the backend.
            if case .unavailable(reason: .notInitialized, _) = _userWalletPushStatusSubject.value {
                _userWalletPushStatusSubject.send(pushNotifyStatus)
                return
            }

            // Checking the deduplication of a status update call
            if pushNotifyStatus != _userWalletPushStatusSubject.value {
                updateWalletPushNotifyStatus(pushNotifyStatus)
            }
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
