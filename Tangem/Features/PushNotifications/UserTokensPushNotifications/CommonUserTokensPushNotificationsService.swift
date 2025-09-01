//
//  CommonUserTokensPushNotificationsService.swift
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

final class CommonUserTokensPushNotificationsService: NSObject {
    // MARK: - Services

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) var userWalletRepository: UserWalletRepository
    @Injected(\.pushNotificationsInteractor) var pushNotificationsInteractor: PushNotificationsInteractor
    @Injected(\.pushNotificationsPermission) var pushNotificationsPermissionService: PushNotificationsPermissionService

    // MARK: - Private Properties

    private let _applicationEntries: CurrentValueSubject<[ApplicationWalletEntry], Never> = .init([])

    @MainActor private var isInitialized = false

    private var initialSubscription: AnyCancellable?
    private var permissionSubscription: AnyCancellable?
    private var reproducedBag: Set<AnyCancellable> = []
    private var updateStateTask: Task<Void, Never>?

    /// Subject for synchronizing the initialization request and receiving events from userWalletRepository.
    private var _syncEventSubject: PassthroughSubject<Void, Never> = .init()

    private var applicationUid: String {
        AppSettings.shared.applicationUid
    }

    // MARK: - Implementation

    /// Initializes the push notifications service.
    /// Checks the registration of appUid (creates or updates the application on the server),
    /// updates the isInitialized flag, and fetches the list of wallets linked to the appUid.
    /// After successful initialization, sends a synchronization event.
    func initialize() {
        guard FeatureProvider.isAvailable(.pushTransactionNotifications) else {
            return
        }

        runTask(in: self) { service in
            let fcmToken = Messaging.messaging().fcmToken ?? ""

            switch service.defineInitializeType() {
            case .create:
                await service.createApplication(fcmToken: fcmToken)
            case .update:
                await service.updateApplication(fcmToken: fcmToken)
            }

            await service.update(isInitialized: true)

            await service.fetchEntries()

            service._syncEventSubject.send(())
        }
    }

    // MARK: - Private Implementation

    override init() {
        super.init()

        Messaging.messaging().delegate = self

        bind()
    }

    /// Subscribes to repository changes using combineLatest to ensure the service is fully initialized before handling events.
    private func bind() {
        initialSubscription = _syncEventSubject
            .combineLatest(userWalletRepository.eventProvider)
            .map(\.1)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .receiveValue { service, event in
                service.handleUserWalletUpdates(by: event)
            }

        // It is used for existing versions in order to automatically show a notification to the user about transactions.
        permissionSubscription = _syncEventSubject
            .combineLatest(pushNotificationsInteractor.permissionRequestPublisher)
            .map(\.1)
            .withWeakCaptureOf(self)
            .sink { service, request in
                guard case .allow(.afterLogin) = request else {
                    return
                }

                service.permissionRequestInitialPushAllowanceForExistingWallets()
            }
    }

    /// Subscribes to changes in the wallet name state.
    /// The subscription is stored in reproducedBag because it is recreated each time the repository changes.
    private func bindWhenUserWalletRepositoryDidUpdated() {
        reproducedBag.removeAll()

        userWalletRepository.models.map {
            $0.userWalletNamePublisher.dropFirst()
        }
        .merge()
        .withWeakCaptureOf(self)
        .sink { service, _ in
            let pendingNameUpdates = service.findUserWalletsToUpdate()

            pendingNameUpdates.forEach {
                if case .name(let value, let userWalletId) = $0 {
                    service.updateRemoteWallet(name: value, by: userWalletId)
                }
            }
        }
        .store(in: &reproducedBag)
    }

    private func handleUserWalletUpdates(by event: UserWalletRepositoryEvent) {
        switch event {
        case .inserted, .unlocked, .deleted, .unlockedBiometrics:
            updateState()
        default:
            return
        }
    }

    private func updateState() {
        updateStateTask?.cancel()

        updateStateTask = runTask(in: self) { @MainActor service in
            await service.updateEntryByUserWalletModelIfNeeded()
            service.bindWhenUserWalletRepositoryDidUpdated()
        }
    }
}

// MARK: - ApplicationRepository

extension CommonUserTokensPushNotificationsService: UserTokensPushNotificationsService {
    var entries: [ApplicationWalletEntry] {
        _applicationEntries.value
    }

    var entriesPublisher: AnyPublisher<[ApplicationWalletEntry], Never> {
        _applicationEntries.eraseToAnyPublisher()
    }

    func updateWallet(notifyStatus: Bool, by userWalletId: String) {
        updateLocalWalletNotifyStatus(notifyStatus, by: userWalletId)
    }
}

// MARK: - Private Implementation

private extension CommonUserTokensPushNotificationsService {
    func defineInitializeType() -> InitializeType {
        applicationUid.isEmpty ? .create : .update
    }

    func createApplication(fcmToken: String) async {
        do {
            let deviceInfo = DeviceInfo()

            let requestModel = ApplicationDTO.Request(
                pushToken: fcmToken,
                platform: deviceInfo.platform,
                device: deviceInfo.device,
                systemVersion: deviceInfo.systemVersion,
                language: deviceInfo.appLanguageCode,
                timezone: deviceInfo.timezone,
                version: deviceInfo.version
            )

            let response = try await tangemApiService.createUserWalletsApplications(requestModel: requestModel)

            await MainActor.run {
                AppLogger.info("Application uid: \(response.uid)")
                AppSettings.shared.applicationUid = response.uid
                AppSettings.shared.lastStoredFCMToken = fcmToken
            }
        } catch {
            AppLogger.error(error: error)
        }
    }

    func updateApplication(fcmToken: String?) async {
        do {
            let requestModel = ApplicationDTO.Update.Request(pushToken: fcmToken)
            try await tangemApiService.updateUserWalletsApplications(uid: applicationUid, requestModel: requestModel)

            await MainActor.run {
                AppSettings.shared.lastStoredFCMToken = fcmToken
            }

            AppLogger.info("Application did updated by uid: \(applicationUid)")
        } catch {
            AppLogger.error(error: error)
        }
    }

    func fetchEntries() async {
        do {
            let response = try await tangemApiService.getUserWallets(applicationUid: applicationUid)

            let arrayEntries = response.map {
                ApplicationWalletEntry(id: $0.id, name: $0.name ?? "", notifyStatus: $0.notifyStatus)
            }

            let uniqueEntries = Set(arrayEntries)

            await update(entries: Array(uniqueEntries))

            arrayEntries.forEach {
                updateLocalWallet(name: $0.name, by: $0.id)
            }
        } catch {
            AppLogger.error(error: error)
            await update(entries: [])
        }
    }

    func updateLocalWalletNotifyStatus(_ status: Bool, by userWalletId: String) {
        let toLocalUpdateEntries = _applicationEntries.value.map {
            let updateNotifyStatus = $0.id == userWalletId ? status : $0.notifyStatus
            return ApplicationWalletEntry(id: $0.id, name: $0.name, notifyStatus: updateNotifyStatus)
        }

        runTask { [weak self] in
            await self?.update(entries: toLocalUpdateEntries)
        }
    }

    func updateEntryByUserWalletModelIfNeeded() async {
        guard await AppSettings.shared.saveUserWallets else {
            await createAndConnectWallet(entries: [])
            return
        }

        let userWalletModels = userWalletRepository.models

        let isAuthorizedPushNotifications = await pushNotificationsPermissionService.isAuthorized

        let toUpdateEntries = userWalletModels.map {
            let initialNotifyStatus = getInitialPushStatusWithAllowance(
                userWalletId: $0.userWalletId,
                status: $0.userTokensPushNotificationsManager.status,
                isAuthorized: isAuthorizedPushNotifications
            )

            return ApplicationWalletEntry(
                id: $0.userWalletId.stringValue,
                name: $0.name,
                notifyStatus: initialNotifyStatus
            )
        }

        let differenceEntries = Set(entries.map { $0.id }).symmetricDifference(Set(toUpdateEntries.map { $0.id }))

        guard !differenceEntries.isEmpty else {
            return
        }

        await createAndConnectWallet(entries: toUpdateEntries)
    }

    func createAndConnectWallet(entries: [ApplicationWalletEntry]) async {
        let toUpdateItems = entries.map {
            UserWalletDTO.Create.Request(id: $0.id, name: $0.name)
        }.toSet()

        do {
            try await tangemApiService.createAndConnectUserWallet(
                applicationUid: applicationUid,
                items: toUpdateItems
            )

            await update(entries: entries)
        } catch {
            // Do nothing. If the wallet is not connected to the app, it simply will not receive push messages, and you can try to connect it again.
            AppLogger.error(error: error)
        }
    }

    @MainActor
    func update(entries: [ApplicationWalletEntry]) async {
        _applicationEntries.send(entries)
    }

    @MainActor
    func update(isInitialized: Bool) async {
        self.isInitialized = isInitialized
    }
}

// MARK: - UserWalletModel with wallet name update implementation

private extension CommonUserTokensPushNotificationsService {
    func findUserWalletsToUpdate() -> [PendingToUpdateUserWalletItem] {
        var pendingUpdates: [PendingToUpdateUserWalletItem] = []
        let userWalletModels = userWalletRepository.models

        userWalletModels.forEach { userWalletModel in
            guard let entry = entries.first(where: { $0.id == userWalletModel.userWalletId.stringValue }) else {
                return
            }

            if userWalletModel.name != entry.name {
                pendingUpdates.append(.name(value: userWalletModel.name, userWalletId: userWalletModel.userWalletId.stringValue))
            }
        }

        return pendingUpdates
    }

    func updateRemoteWallet(name: String, by userWalletId: String) {
        runTask { [weak self] in
            guard let self else {
                return
            }

            do {
                let requestModel = UserWalletDTO.Update.Request(name: name)
                try await tangemApiService.updateUserWallet(by: userWalletId, requestModel: requestModel)

                let toLocalUpdateEntries = _applicationEntries.value.map {
                    let updateName = $0.id == userWalletId ? name : $0.name
                    return ApplicationWalletEntry(id: $0.id, name: updateName, notifyStatus: $0.notifyStatus)
                }

                await update(entries: toLocalUpdateEntries)
            } catch {
                AppLogger.error(error: error)
                return
            }
        }
    }

    func updateLocalWallet(name: String, by userWalletId: String) {
        guard let userWalletModel = userWalletRepository.models.first(where: {
            $0.userWalletId.stringValue == userWalletId && $0.name != name
        }) else {
            return
        }

        userWalletModel.updateWalletName(name)
    }
}

// MARK: - Allowance with permissions requests

private extension CommonUserTokensPushNotificationsService {
    func permissionRequestInitialPushAllowanceForExistingWallets() {
        for userWalletModel in userWalletRepository.models {
            let toUpdateNotifyStatus = allowancePushNotifyStatus(
                for: userWalletModel.userWalletId,
                currentNotifyStatus: true
            )

            updateLocalWalletNotifyStatus(toUpdateNotifyStatus, by: userWalletModel.userWalletId.stringValue)
        }
    }

    func getInitialPushStatusWithAllowance(
        userWalletId: UserWalletId,
        status: UserWalletPushNotifyStatus,
        isAuthorized: Bool
    ) -> Bool {
        // Force enable Push Notifications if wallet did set status notInitialized and Push Permission service has status isAuthorized
        if status.isNotInitialized, isAuthorized {
            return allowancePushNotifyStatus(for: userWalletId, currentNotifyStatus: true)
        }

        // Fallback. Set with current status notifications manager
        return status.isActive
    }

    func allowancePushNotifyStatus(for userWalletId: UserWalletId, currentNotifyStatus: Bool) -> Bool {
        let allowanceUserWalletIdTransactionsPush = AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue)

        if !allowanceUserWalletIdTransactionsPush {
            AppSettings.shared.allowanceUserWalletIdTransactionsPush.append(userWalletId.stringValue)

            // We will force the update of the push stats on the backend, provided that the system permissions have been issued in definePushNotifyStatus
            return true
        }

        return currentNotifyStatus
    }
}

// MARK: - Data Types

extension CommonUserTokensPushNotificationsService {
    enum InitializeType {
        case create
        case update
    }

    enum PendingToUpdateUserWalletItem {
        case name(value: String, userWalletId: String)
    }

    enum Constants {
        static let defaultNotifyStatus = false
    }
}

// MARK: - MessagingDelegate

extension CommonUserTokensPushNotificationsService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        runTask(in: self) { service in
            // Skip when service did not initilized
            guard await service.isInitialized else {
                return
            }

            let appUid = await AppSettings.shared.applicationUid
            let lastStoredFCMToken = await AppSettings.shared.lastStoredFCMToken

            if !appUid.isEmpty, lastStoredFCMToken != fcmToken {
                await service.updateApplication(fcmToken: fcmToken)
            }
        }
    }
}
