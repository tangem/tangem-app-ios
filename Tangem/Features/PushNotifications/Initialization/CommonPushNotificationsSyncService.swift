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

    private let applicationClient = PushNotificationsSyncApplicationsClient()
    private let walletsStateClient = PushNotificationsSyncWalletsClient()

    private lazy var walletNameClient = PushNotificationsSyncWalletNameClient(
        tangemApiService: tangemApiService,
        userWalletRepository: userWalletRepository
    )

    private var initialSubscription: AnyCancellable?
    private var appSettingsSubscription: AnyCancellable?
    private var eventProviderSubscription: AnyCancellable?

    private var updateStateTask: Task<Void, Never>?

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
            AppLogger.info("Did receive event: \(event)")
            updateState()
        default:
            return
        }
    }

    private func updateState() {
        updateStateTask?.cancel()

        updateStateTask = runTask(in: self) { service in
            do {
                try await service.walletsStateClient
                    .syncUserWalletModelState(applicationUid: service.applicationUid)
                await service.walletNameClient.restartObserving()
            } catch {
                AppLogger.info("Failed sync remote with remote wallets state")
                service.walletsStateClient.handleSyncErrorForAllWallets()
            }
        }
    }
}

// MARK: - PushNotificationsSyncService

extension CommonPushNotificationsSyncService: PushNotificationsSyncService {
    /// Initializes the push notifications service.
    /// Checks the registration of appUid (creates or updates the application on the server),
    /// fetches the list of wallets linked to the appUid.
    /// After successful initialization, notifies downstream subscribers.
    func initialize() {
        runTask(in: self) { service in
            let fcmToken = Messaging.messaging().fcmToken ?? ""
            let uid = service.applicationUid

            do {
                switch service.applicationClient.initializeType(applicationUid: uid) {
                case .create:
                    try await service.applicationClient.createApplication(fcmToken: fcmToken)
                case .update:
                    try await service.applicationClient.updateApplication(fcmToken: fcmToken, applicationUid: uid)
                }
            } catch {
                AppLogger.error("Failed to initialize push notifications service", error: error)
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
                try await service.applicationClient.updateApplication(fcmToken: fcmToken, applicationUid: appUid)
            } catch {
                AppLogger.error("Failed to update FCM token", error: error)
            }
        }
    }
}
