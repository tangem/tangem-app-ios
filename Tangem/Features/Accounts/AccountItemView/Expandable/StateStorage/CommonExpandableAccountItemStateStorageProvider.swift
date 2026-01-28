//
//  CommonExpandableAccountItemStateStorageProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

/// Aggregated storage for expandable account item states for all user wallets and accounts, single instance per app.
final class CommonExpandableAccountItemStateStorageProvider {
    private typealias Storage = [String: Bool]

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    /// - Warning: Direct modification of this property will not trigger `didUpdatePublisher`,
    /// use `mutateStorage(storage:userWalletId:mutation:)` method instead.
    @AppStorageCompat(StorageKeys.persistentStorage)
    private var persistentStorage: Storage = [:]

    /// - Warning: Direct modification of this property will not trigger `didUpdatePublisher`,
    /// use `mutateStorage(storage:userWalletId:mutation:)` method instead.
    private var inMemoryStorage: Storage = [:]

    private let didChangeSubject = PassthroughSubject<UserWalletId, Never>()

    private var userWalletRepositorySubscription: AnyCancellable?

    private var userWalletModelsSubscriptions: [UserWalletId: AnyCancellable] = [:]

    fileprivate init() {}

    private func bind() {
        userWalletRepositorySubscription = userWalletRepository
            .eventProvider
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { storage, event in
                storage.handleUserWalletRepositoryEvent(event)
            }
    }

    private func subscribeToUserWalletModelsIfNeeded(_ userWalletModels: [UserWalletModel]) {
        for userWalletModel in userWalletModels {
            let userWalletId = userWalletModel.userWalletId

            guard userWalletModelsSubscriptions[userWalletId] == nil else {
                continue
            }

            userWalletModelsSubscriptions[userWalletId] = userWalletModel
                .accountModelsManager
                .accountModelsPublisher
                .map { $0.cryptoAccounts() }
                .prepend([]) // Triggers initial `pairwise` call
                .pairwise()
                .withWeakCaptureOf(self)
                .sink { storage, input in
                    storage.handleCryptoAccounts(
                        oldCryptoAccounts: input.0,
                        newCryptoAccounts: input.1,
                        inUserWalletModelWithIdentifier: userWalletId
                    )
                }
        }
    }

    private func handleDeletedUserWalletModelsWithIdentifiers(_ userWalletIds: [UserWalletId]) {
        for userWalletId in userWalletIds {
            let storageKeyPrefix = ExpandableAccountItemStateStorageKeyHelper.makeStorageKeyPrefix(
                userWalletId: userWalletId
            )

            mutateStorage(storage: \.inMemoryStorage, userWalletId: userWalletId) { storage in
                storage.removeAll { $0.key.hasPrefix(storageKeyPrefix) }
            }

            mutateStorage(storage: \.persistentStorage, userWalletId: userWalletId) { storage in
                storage.removeAll { $0.key.hasPrefix(storageKeyPrefix) }
            }

            userWalletModelsSubscriptions.removeValue(forKey: userWalletId)
        }
    }

    private func handleCryptoAccounts(
        oldCryptoAccounts: [CryptoAccounts],
        newCryptoAccounts: [CryptoAccounts],
        inUserWalletModelWithIdentifier userWalletId: UserWalletId
    ) {
        let newCryptoAccountsIds = mapToPersistentIdentifiers(newCryptoAccounts)

        let newCryptoAccountsIdsFilter = newCryptoAccountsIds
            .map { $0.toPersistentIdentifier().toAnyHashable() }
            .toSet()

        let removedCryptoAccountsIds = mapToPersistentIdentifiers(oldCryptoAccounts)
            .filter { !newCryptoAccountsIdsFilter.contains($0.toPersistentIdentifier().toAnyHashable()) }

        for accountId in removedCryptoAccountsIds {
            let storageKey = ExpandableAccountItemStateStorageKeyHelper.makeStorageKey(
                accountId: accountId,
                userWalletId: userWalletId
            )

            mutateStorage(storage: \.inMemoryStorage, userWalletId: userWalletId) { storage in
                storage.removeValue(forKey: storageKey)
            }

            mutateStorage(storage: \.persistentStorage, userWalletId: userWalletId) { storage in
                storage.removeValue(forKey: storageKey)
            }
        }

        // Single account in a multiple accounts mode should be expanded by default
        let shouldAutoExpandSingleAccount = newCryptoAccounts.hasMultipleAccounts && newCryptoAccountsIds.count == 1
        for accountId in newCryptoAccountsIds {
            let storageKey = ExpandableAccountItemStateStorageKeyHelper.makeStorageKey(
                accountId: accountId,
                userWalletId: userWalletId
            )

            // No need to update `persistentStorage` here because the condition mentioned in the comment above is a transient one
            mutateStorage(storage: \.inMemoryStorage, userWalletId: userWalletId) { storage in
                storage[storageKey] = shouldAutoExpandSingleAccount
            }
        }
    }

    private func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(let userWalletIds):
            handleDeletedUserWalletModelsWithIdentifiers(userWalletIds)
        case .unlocked:
            subscribeToUserWalletModelsIfNeeded(userWalletRepository.models)
        case .unlockedWallet(let userWalletId),
             .inserted(let userWalletId):
            if let userWalletModel = userWalletRepository.models[userWalletId] {
                subscribeToUserWalletModelsIfNeeded([userWalletModel])
            }
        default:
            break
        }
    }

    private func mapToPersistentIdentifiers(_ cryptoAccounts: [CryptoAccounts]) -> [any AccountModelPersistentIdentifierConvertible] {
        return cryptoAccounts
            .reduce(into: [any CryptoAccountModel]()) { partialResult, element in
                switch element {
                case .single(let account):
                    partialResult.append(account)
                case .multiple(let accounts):
                    partialResult.append(contentsOf: accounts)
                }
            }
            // Explicit type casting, as current version of the Swift compiler crashes with the following assertion:
            // `Assertion failed: (!componentTy->hasTypeParameter()), function emitKeyPathComponentForDecl at SILGenExpr.cpp:4698.`
            .map { $0.id as (any AccountModelPersistentIdentifierConvertible) }
    }

    private func mutateStorage(
        storage: ReferenceWritableKeyPath<CommonExpandableAccountItemStateStorageProvider, Storage>,
        userWalletId: UserWalletId,
        mutation: (inout Storage) -> Void
    ) {
        mutation(&self[keyPath: storage])
        didChangeSubject.send(userWalletId)
    }
}

// MARK: - ExpandableAccountItemStateStorageProvider protocol conformance

extension CommonExpandableAccountItemStateStorageProvider: ExpandableAccountItemStateStorageProvider {
    func makeStateStorage(for userWalletId: UserWalletId) -> ExpandableAccountItemStateStorage {
        return StateStorage(userWalletId: userWalletId, innerStorage: self)
    }
}

// MARK: - Initializable protocol conformance

extension CommonExpandableAccountItemStateStorageProvider: Initializable {
    func initialize() {
        subscribeToUserWalletModelsIfNeeded(userWalletRepository.models)
        bind()
    }
}

// MARK: - Auxiliary types

private extension CommonExpandableAccountItemStateStorageProvider {
    enum StorageKeys: String, RawRepresentable {
        case persistentStorage = "tangem_expandable_account_item_state_storage"
    }

    /// User wallet-specific storage for expandable account item states, single instance per user wallet.
    struct StateStorage: ExpandableAccountItemStateStorage {
        var didUpdatePublisher: AnyPublisher<Void, Never> {
            // We are only interested in changes related to this specific user wallet
            innerStorage
                .didChangeSubject
                .filter { $0 == userWalletId }
                .mapToVoid()
                .eraseToAnyPublisher()
        }

        private let userWalletId: UserWalletId
        private let innerStorage: CommonExpandableAccountItemStateStorageProvider

        init(
            userWalletId: UserWalletId,
            innerStorage: CommonExpandableAccountItemStateStorageProvider
        ) {
            self.userWalletId = userWalletId
            self.innerStorage = innerStorage
        }

        func isExpanded(_ accountModel: some BaseAccountModel) -> Bool {
            let storageKey = ExpandableAccountItemStateStorageKeyHelper.makeStorageKey(
                accountId: accountModel.id,
                userWalletId: userWalletId
            )

            // Persistent storage has higher priority because it reflects the last known explicit user choice
            return innerStorage.persistentStorage[storageKey] ?? innerStorage.inMemoryStorage[storageKey] ?? false
        }

        func setIsExpanded(_ isExpanded: Bool, for accountModel: some BaseAccountModel) {
            let storageKey = ExpandableAccountItemStateStorageKeyHelper.makeStorageKey(
                accountId: accountModel.id,
                userWalletId: userWalletId
            )

            // No need to update `inMemoryStorage` here because `persistentStorage` always has higher priority
            innerStorage.mutateStorage(storage: \.persistentStorage, userWalletId: userWalletId) { storage in
                storage[storageKey] = isExpanded
            }
        }
    }
}

// MARK: - Injection

extension InjectedValues {
    var expandableAccountItemStateStorageProvider: ExpandableAccountItemStateStorageProvider {
        get { Self[CommonExpandableAccountItemStateStorageProvider.Key.self] }
        set { Self[CommonExpandableAccountItemStateStorageProvider.Key.self] = newValue }
    }
}

private extension CommonExpandableAccountItemStateStorageProvider {
    struct Key: InjectionKey {
        static var currentValue: ExpandableAccountItemStateStorageProvider = CommonExpandableAccountItemStateStorageProvider()
    }
}
