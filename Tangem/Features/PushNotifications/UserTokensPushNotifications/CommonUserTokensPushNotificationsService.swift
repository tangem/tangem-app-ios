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

final class CommonUserTokensPushNotificationsService: NSObject {
    // MARK: - Services

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) var userWalletRepository: UserWalletRepository

    // MARK: - Private Properties

    private let _applicationEntries: CurrentValueSubject<[ApplicationWalletEntry], Never> = .init([])

    private var isInitialized = false

    private var initialBag: Set<AnyCancellable> = []
    private var reproducedBag: Set<AnyCancellable> = []
    private var updateStateTask: Task<Void, Never>?

    private var applicationUid: String {
        AppSettings.shared.applicationUid
    }

    // MARK: - Implementation

    func initialize() {
        guard FeatureProvider.isAvailable(.pushTransactionNotifications) else {
            return
        }

        runTask { [weak self] in
            guard let self else { return }

            let fcmToken = Messaging.messaging().fcmToken ?? ""

            switch defineInitializeType() {
            case .create:
                await createApplication(fcmToken: fcmToken)
            case .update:
                await updateApplication(fcmToken: fcmToken)
            }

            await MainActor.run {
                self.isInitialized = true
            }

            await fetchEntries()

            bind()
        }
    }

    // MARK: - Private Implementation

    override init() {
        super.init()

        Messaging.messaging().delegate = self
    }

    private func bind() {
        userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { service, event in
                service.handleUserWalletUpdates(by: event)
            }
            .store(in: &initialBag)
    }

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
        case .locked, .selected, .scan:
            return
        case .inserted, .updated, .deleted, .biometryUnlocked, .replaced:
            updateState()
        }
    }

    private func updateState() {
        updateEntryByUserWalletModelIfNeeded()
        bindWhenUserWalletRepositoryDidUpdated()
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

    func updateEntryByUserWalletModelIfNeeded() {
        let userWalletModels = userWalletRepository.models

        let toUpdateEntries = userWalletModels.map {
            ApplicationWalletEntry(
                id: $0.userWalletId.stringValue,
                name: $0.name,
                notifyStatus: $0.userTokensPushNotificationsManager.status.isActive
            )
        }

        let differenceEntries = Set(entries.map { $0.id }).symmetricDifference(Set(toUpdateEntries.map { $0.id }))

        guard !differenceEntries.isEmpty else {
            return
        }

        let toUpdateItems = toUpdateEntries.map {
            UserWalletDTO.Create.Request(id: $0.id, name: $0.name)
        }

        updateStateTask?.cancel()

        updateStateTask = runTask(in: self) { service in
            do {
                try await service.tangemApiService.createAndConnectUserWallet(
                    applicationUid: service.applicationUid,
                    items: toUpdateItems
                )

                await service.update(entries: toUpdateEntries)
            } catch {
                // Do nothing. If the wallet is not connected to the app, it simply will not receive push messages, and you can try to connect it again.
                AppLogger.error(error: error)
            }
        }
    }

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

    @MainActor
    func update(entries: [ApplicationWalletEntry]) async {
        _applicationEntries.send(entries)
    }
}

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

extension CommonUserTokensPushNotificationsService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Skip when service did not initilized
        guard isInitialized else {
            return
        }

        let appUid = AppSettings.shared.applicationUid
        let lastStoredFCMToken = AppSettings.shared.lastStoredFCMToken

        if !appUid.isEmpty, lastStoredFCMToken != fcmToken {
            runTask { [weak self] in
                await self?.updateApplication(fcmToken: fcmToken)
            }
        }
    }
}
