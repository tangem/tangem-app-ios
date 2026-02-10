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

    private var initialSubscription: AnyCancellable?
    private var permissionSubscription: AnyCancellable?
    private var appSettingsSubscription: AnyCancellable?
    private var eventProviderSubscription: AnyCancellable?

    private var reproducedBag: Set<AnyCancellable> = []

    private var updateStateTask: Task<Void, Never>?

    /// Subject for synchronizing the initialization request and receiving events from userWalletRepository.
    private var _syncEventSubject: PassthroughSubject<Void, Never> = .init()

    /// Caches the latest `UserWalletRepositoryEvent` to avoid losing events emitted before initialization completes
    private var _userWalletEventSubject: CurrentValueSubject<UserWalletRepositoryEvent?, Never> = .init(nil)

    private var applicationUid: String {
        AppSettings.shared.applicationUid
    }

    // MARK: - Private Implementation

    override init() {
        super.init()

        Messaging.messaging().delegate = self

        bind()
    }

    /// Subscribes to repository changes using combineLatest to ensure the service is fully initialized before handling events.
    private func bind() {
        // Bridge repository events into a replayable subject
        eventProviderSubscription = userWalletRepository.eventProvider
            .withWeakCaptureOf(self)
            .sink { service, event in
                service._userWalletEventSubject.send(event)
            }

        initialSubscription = _syncEventSubject
            .combineLatest(_userWalletEventSubject.compactMap { $0 })
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
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { service, request in
                switch request {
                case .allow(.afterLogin), .allow(.afterLoginBanner):
                    service.permissionRequestInitialPushAllowanceForExistingWallets()
                default:
                    break
                }
            }

        /*
         This subscription is needed for workaround to enable biometrics and change the status of push notifications. Since the wallet repository does not generate any events. Filtering is only true because disabling push biometrics generates events in the wallet repository and there is no need to track false
         */
        appSettingsSubscription = _syncEventSubject
            .combineLatest(AppSettings
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

    /// Subscribes to changes in the wallet name state.
    /// The subscription is stored in reproducedBag because it is recreated each time the repository changes.
    private func bindWhenUserWalletRepositoryDidUpdated() {
        reproducedBag.removeAll()

        userWalletRepository.models.map {
            $0.updatePublisher.compactMap(\.newName)
        }
        .merge()
        .withWeakCaptureOf(self)
        .sink { service, _ in
            let pendingNameUpdates = service.findUserWalletsToUpdate()

            pendingNameUpdates.forEach {
                if case .name(let value, let userWalletId, let context) = $0 {
                    service.updateRemoteWallet(name: value, context: context, userWalletId: userWalletId)
                }
            }
        }
        .store(in: &reproducedBag)
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

    /// Initializes the push notifications service.
    /// Checks the registration of appUid (creates or updates the application on the server),
    /// fetches the list of wallets linked to the appUid.
    /// After successful initialization, sends a synchronization event.
    func initialize() {
        runTask(in: self) { service in
            let fcmToken = Messaging.messaging().fcmToken ?? ""

            do {
                switch service.defineInitializeType() {
                case .create:
                    try await service.createApplication(fcmToken: fcmToken)
                case .update:
                    try await service.updateApplication(fcmToken: fcmToken)
                }
            } catch {
                AppLogger.error("Failed to initialize push notifications service", error: error)
                return
            }

            await service.fetchEntries()

            service._syncEventSubject.send(())
        }
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

    func createApplication(fcmToken: String) async throws {
        let deviceInfo = DeviceInfo()

        let requestModel = ApplicationDTO.Request(
            pushToken: fcmToken,
            platform: deviceInfo.platform,
            device: deviceInfo.device,
            systemVersion: deviceInfo.systemVersion,
            language: deviceInfo.appLanguageCode,
            timezone: deviceInfo.timezone,
            version: deviceInfo.version,
            appsflyerId: AppsFlyerWrapper.shared.appsflyerId
        )

        let response = try await tangemApiService.createUserWalletsApplications(requestModel: requestModel)

        AppLogger.info("Application has been created for uid: \(response.uid)")

        await MainActor.run {
            AppSettings.shared.applicationUid = response.uid
            AppSettings.shared.lastStoredFCMToken = fcmToken
        }
    }

    func updateApplication(fcmToken: String?) async throws {
        let requestModel = ApplicationDTO.Update.Request(pushToken: fcmToken)
        try await tangemApiService.updateUserWalletsApplications(uid: applicationUid, requestModel: requestModel)

        AppLogger.info("Application has been updated for uid: \(applicationUid)")

        await MainActor.run {
            AppSettings.shared.lastStoredFCMToken = fcmToken
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
            await connectWallets(entries: [])
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

        await connectWallets(entries: toUpdateEntries)
    }

    func connectWallets(entries: [ApplicationWalletEntry], shouldRetry: Bool = true) async {
        do {
            let walletIds = entries.uniqueProperties(\.id)
            let request = ApplicationDTO.Connect.Request(walletIds: walletIds)
            try await tangemApiService.connectUserWallets(uid: applicationUid, requestModel: request)
            await update(entries: entries)
        } catch let error as TangemAPIError where error.code == .badRequest {
            if shouldRetry {
                await createMissingWallets(entries: entries)
                await connectWallets(entries: entries, shouldRetry: false)
            } else {
                AppLogger.error(error: error)
            }
        } catch {
            // Do nothing. If the wallet is not connected to the app, it simply will not receive push messages, and you can try to connect it again.
            AppLogger.error(error: error)
        }
    }

    func createMissingWallets(entries: [ApplicationWalletEntry]) async {
        await withTaskGroup { group in
            for entry in entries {
                guard let model = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == entry.id }) else {
                    return
                }

                let remoteIdentifierBuilder = CryptoAccountsRemoteIdentifierBuilder(userWalletId: model.userWalletId)
                let mapper = CryptoAccountsNetworkMapper(
                    supportedBlockchains: model.config.supportedBlockchains,
                    remoteIdentifierBuilder: remoteIdentifierBuilder.build(from:)
                )
                let walletsNetworkService = CommonWalletsNetworkService(userWalletId: model.userWalletId)
                let networkService = CommonCryptoAccountsNetworkService(
                    userWalletId: model.userWalletId,
                    mapper: mapper,
                    walletsNetworkService: walletsNetworkService
                )
                let helper = WalletCreationHelper(
                    userWalletId: model.userWalletId,
                    userWalletName: model.name,
                    userWalletConfig: model.config,
                    networkService: networkService
                )

                group.addTask {
                    try? await helper.createWallet()
                }
            }

            await group.waitForAll()
        }
    }

    @MainActor
    func update(entries: [ApplicationWalletEntry]) async {
        _applicationEntries.send(entries)
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
                let context = userWalletModel.config
                    .contextBuilder
                    .enrich(withName: userWalletModel.name)
                    .build()

                pendingUpdates.append(.name(
                    value: userWalletModel.name,
                    userWalletId: userWalletModel.userWalletId.stringValue,
                    context: context
                ))
            }
        }

        return pendingUpdates
    }

    func updateRemoteWallet(name: String, context: some Encodable, userWalletId: String) {
        runTask { [weak self] in
            guard let self else {
                return
            }

            do {
                try await tangemApiService.updateWallet(by: userWalletId, context: context)

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
            $0.userWalletId.stringValue == userWalletId
        }) else {
            return
        }

        if name.isEmpty, userWalletModel.name.isEmpty {
            let defaultName = UserWalletNameIndexationHelper().suggestedName(userWalletConfig: userWalletModel.config)
            userWalletModel.update(type: .newName(defaultName))
            return
        }

        if name.isEmpty, userWalletModel.name.isNotEmpty {
            return
        }

        if name == userWalletModel.name {
            return
        }

        userWalletModel.update(type: .newName(name))
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
        case name(value: String, userWalletId: String, context: Encodable)
    }

    enum Constants {
        static let defaultNotifyStatus = false
    }
}

// MARK: - MessagingDelegate

extension CommonUserTokensPushNotificationsService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        runTask(in: self) { service in
            let appUid = await AppSettings.shared.applicationUid
            let lastStoredFCMToken = await AppSettings.shared.lastStoredFCMToken

            if !appUid.isEmpty, lastStoredFCMToken != fcmToken {
                do {
                    try await service.updateApplication(fcmToken: fcmToken)
                } catch {
                    AppLogger.error("Failed to update FCM token", error: error)
                }
            }
        }
    }
}
