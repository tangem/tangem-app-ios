//
//  CommonMobileUpgradeBannerStorageManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonMobileUpgradeBannerStorageManager {
    typealias Storage = [String: Date]

    @AppStorageCompat(StorageType.mobileUpgradeBannerClosed)
    private var closedBannersStorage: Storage = [:]

    @AppStorageCompat(StorageType.mobileUpgradeBannerWalletCreated)
    private var createdWalletsStorage: Storage = [:]

    @AppStorageCompat(StorageType.mobileUpgradeBannerWalletToppedUp)
    private var toppedUpWalletsStorage: Storage = [:]

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let mutationSubject = PassthroughSubject<StorageMutation, Never>()

    private var mutationsSubscription: AnyCancellable?
    private var repositoryEventsSubscription: AnyCancellable?

    fileprivate init() {}
}

// MARK: - Private methods

private extension CommonMobileUpgradeBannerStorageManager {
    func bind() {
        mutationsSubscription = mutationSubject
            .withWeakCaptureOf(self)
            .sink { manager, mutation in
                manager.mutateStorage(mutation: mutation)
            }

        repositoryEventsSubscription = userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { manager, event in
                manager.handleRepository(event: event)
            }
    }

    func handleRepository(event: UserWalletRepositoryEvent) {
        switch event {
        case .inserted(let userWalletId):
            store(userWalletId: userWalletId, walletCreateDate: Date())
        case .unlocked, .unlockedWallet:
            ensureWalletCreateAreStored()
        case .deleted(let userWalletIds, _):
            userWalletIds.forEach(clean)
        default:
            break
        }
    }

    /// Ensures that wallet creation dates are stored for wallets that were created before upgrade feature.
    func ensureWalletCreateAreStored() {
        let unStoredModels = userWalletRepository.models.filter {
            getWalletCreateDate(userWalletId: $0.userWalletId) == nil
        }
        let walletCreateDate = Date()
        unStoredModels.forEach { store(userWalletId: $0.userWalletId, walletCreateDate: walletCreateDate) }
    }

    func store(userWalletId: UserWalletId, walletCreateDate: Date) {
        let mutation = StorageMutation.walletCreate(userWalletId: userWalletId, date: walletCreateDate)
        mutationSubject.send(mutation)
    }

    func clean(userWalletId: UserWalletId) {
        let mutation = StorageMutation.clean(userWalletId: userWalletId)
        mutationSubject.send(mutation)
    }

    func mutateStorage(mutation: StorageMutation) {
        switch mutation {
        case .walletCreate(let userWalletId, let date):
            mutate(storage: \.createdWalletsStorage) { storage in
                storage[userWalletId.stringValue] = date
            }
        case .walletTopUp(let userWalletId, let date):
            mutate(storage: \.toppedUpWalletsStorage) { storage in
                storage[userWalletId.stringValue] = date
            }
        case .bannerClose(let userWalletId, let date):
            mutate(storage: \.closedBannersStorage) { storage in
                storage[userWalletId.stringValue] = date
            }
        case .clean(let userWalletId):
            let key = userWalletId.stringValue
            let mutation: (inout Storage) -> Void = { storage in
                storage.removeValue(forKey: key)
            }
            mutate(storage: \.closedBannersStorage, mutation: mutation)
            mutate(storage: \.createdWalletsStorage, mutation: mutation)
            mutate(storage: \.toppedUpWalletsStorage, mutation: mutation)
        }
    }

    func mutate(
        storage: ReferenceWritableKeyPath<CommonMobileUpgradeBannerStorageManager, Storage>,
        mutation: (inout Storage) -> Void
    ) {
        mutation(&self[keyPath: storage])
    }
}

// MARK: - MobileUpgradeBannerStorageManager

extension CommonMobileUpgradeBannerStorageManager: MobileUpgradeBannerStorageManager {
    func getBannerCloseDate(userWalletId: UserWalletId) -> Date? {
        closedBannersStorage[userWalletId.stringValue]
    }

    func getWalletCreateDate(userWalletId: UserWalletId) -> Date? {
        createdWalletsStorage[userWalletId.stringValue]
    }

    func getWalletTopUpDate(userWalletId: UserWalletId) -> Date? {
        toppedUpWalletsStorage[userWalletId.stringValue]
    }

    func store(userWalletId: UserWalletId, walletTopUpDate: Date) {
        let mutation = StorageMutation.walletTopUp(userWalletId: userWalletId, date: walletTopUpDate)
        mutationSubject.send(mutation)
    }

    func store(userWalletId: UserWalletId, bannerCloseDate: Date) {
        let mutation = StorageMutation.bannerClose(userWalletId: userWalletId, date: bannerCloseDate)
        mutationSubject.send(mutation)
    }
}

// MARK: - Initializable

extension CommonMobileUpgradeBannerStorageManager: Initializable {
    func initialize() {
        bind()
    }
}

// MARK: - Types

private extension CommonMobileUpgradeBannerStorageManager {
    enum StorageMutation {
        case bannerClose(userWalletId: UserWalletId, date: Date)
        case walletCreate(userWalletId: UserWalletId, date: Date)
        case walletTopUp(userWalletId: UserWalletId, date: Date)
        case clean(userWalletId: UserWalletId)
    }
}

// MARK: - Injections

private struct MobileUpgradeBannerStorageManagerKey: InjectionKey {
    static var currentValue: MobileUpgradeBannerStorageManager = CommonMobileUpgradeBannerStorageManager()
}

extension InjectedValues {
    var mobileUpgradeBannerStorageManager: MobileUpgradeBannerStorageManager {
        get { Self[MobileUpgradeBannerStorageManagerKey.self] }
        set { Self[MobileUpgradeBannerStorageManagerKey.self] = newValue }
    }
}
