//
//  CommonPushNotificationsSyncService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import FirebaseMessaging
import Combine
import CombineExt
import UIKit

final class CommonPushNotificationsSyncService: NSObject {
    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private Properties

    private let applicationProvider = PushNotificationsSyncApplicationsProvider()
    private let walletsStateProvider = PushNotificationsSyncWalletsProvider()

    private lazy var walletNameProvider = PushNotificationsSyncWalletNameProvider(
        tangemApiService: tangemApiService,
        userWalletRepository: userWalletRepository
    )

    private var initialSubscription: AnyCancellable?
    private var appSettingsSubscription: AnyCancellable?
    private var eventProviderSubscription: AnyCancellable?

    private var updateStateTask: Task<Void, Never>?
    private var isInitialized = false

    private var applicationUid: String {
        AppSettings.shared.applicationUid
    }

    /// Fires once after remote application registration succeeds so downstream handlers can run.
    private let applicationRegistrationCompletedSubject = PassthroughSubject<Void, Never>()

    /// Latest repository event so events emitted before registration completes are not lost.
    private let userWalletRepositoryEventSubject = CurrentValueSubject<UserWalletRepositoryEvent?, Never>(nil)

    // MARK: - Init

    override init() {
        super.init()

        Messaging.messaging().delegate = self

        bind()
    }

    /// Subscribes to repository changes; `combineLatest` with registration completion ensures handlers run only after the app is registered remotely.
    private func bind() {
        eventProviderSubscription = userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink { service, event in
                service.userWalletRepositoryEventSubject.send(event)
            }

        let repositoryEventsAfterRegistration = applicationRegistrationCompletedSubject
            .combineLatest(userWalletRepositoryEventSubject.compactMap { $0 })
            .map(\.1)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .receiveValue { service, event in
                service.handleUserWalletUpdates(by: event)
            }

        initialSubscription = repositoryEventsAfterRegistration

        /*
         Workaround: enabling biometrics / `saveUserWallets` does not always emit a wallet repository event.
         When `saveUserWallets` becomes true after registration, trigger a sync.
         */
        appSettingsSubscription = applicationRegistrationCompletedSubject
            .combineLatest(
                AppSettings
                    .shared
                    .$saveUserWallets
                    .dropFirst()
                    .removeDuplicates()
            )
            .map(\.1)
            .filter { $0 }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { service, _ in
                service.updateState()
            }
    }

    private func handleUserWalletUpdates(by event: UserWalletRepositoryEvent) {
        switch event {
        case .inserted, .unlocked, .deleted, .unlockedWallet:
            updateState()
        default:
            return
        }
    }

    private func updateState() {
        updateStateTask?.cancel()

        updateStateTask = runTask(in: self) { service in
            do {
                // Stop observing before sync so that server-originated name changes applied
                // inside syncUserWalletModelState do not fire back to the server via the
                // active walletNameProvider subscription left from the previous updateState call.
                // Observing is restarted after sync to capture only user-initiated renames.
                await service.walletNameProvider.stopObserving()

                try await service.walletsStateProvider
                    .syncUserWalletModelState(applicationUid: service.applicationUid)

                for userWalletModel in service.userWalletRepository.models {
                    userWalletModel
                        .userTokensPushNotificationsManager
                        .process(.walletApplicationBindingSynchronized)
                }

                await service.walletNameProvider.restartObserving()
            } catch {
                PushNotificationsSyncServiceLogger.error("Failed to sync wallets state with remote", error: error)
                service.walletsStateProvider.handleSyncErrorForAllWallets()
            }
        }
    }
}

// MARK: - UserTokensPushNotificationsService

extension CommonPushNotificationsSyncService: UserTokensPushNotificationsService {
    /// Initializes the push notifications service.
    /// Checks the registration of appUid (creates or updates the application on the server),
    /// fetches the list of wallets linked to the appUid.
    /// After successful initialization, notifies downstream subscribers.
    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true

        runTask(in: self) { service in
            let fcmToken = Messaging.messaging().fcmToken ?? ""
            let uid = service.applicationUid

            do {
                switch service.applicationProvider.initializeType(applicationUid: uid) {
                case .create:
                    try await service.applicationProvider.createApplication(fcmToken: fcmToken)
                case .update:
                    try await service.applicationProvider.updateApplication(fcmToken: fcmToken, applicationUid: uid)
                }
            } catch {
                PushNotificationsSyncServiceLogger.error("Failed to initialize push notifications sync service", error: error)
                return
            }

            service.applicationRegistrationCompletedSubject.send(())
        }
    }
}

// MARK: - MessagingDelegate

extension CommonPushNotificationsSyncService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        runTask(in: self) { service in
            let appUid = service.applicationUid
            let lastStoredFCMToken = await AppSettings.shared.lastStoredFCMToken

            guard !appUid.isEmpty, lastStoredFCMToken != fcmToken else {
                return
            }

            do {
                try await service.applicationProvider.updateApplication(fcmToken: fcmToken, applicationUid: appUid)
            } catch {
                PushNotificationsSyncServiceLogger.error("Failed to update FCM token", error: error)
            }
        }
    }
}
