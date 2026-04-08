//
//  SwapTokenSelectorExpandedStateStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class SwapTokenSelectorExpandedStateStorage: TokenSelectorExpandedStateStorage {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @AppStorageCompat(StorageKeys.accountStates) private var accountStates: [String: Bool] = [:]
    @AppStorageCompat(StorageKeys.selectedWalletId) private var storedSelectedWalletId: Data? = nil

    private var walletOpenStates: [UserWalletId: Bool] = [:]

    private var userWalletRepositorySubscription: AnyCancellable?
    private var userWalletModelsSubscriptions: [UserWalletId: AnyCancellable] = [:]

    // MARK: - Selected Wallet

    var selectedWalletId: UserWalletId? {
        get { storedSelectedWalletId.map { UserWalletId(value: $0) } }
        set { storedSelectedWalletId = newValue?.value }
    }

    // MARK: - Wallet State

    func isWalletOpen(_ walletId: UserWalletId) -> Bool {
        walletOpenStates[walletId] ?? true
    }

    func setWalletOpen(_ open: Bool, for walletId: UserWalletId) {
        walletOpenStates[walletId] = open
    }

    // MARK: - Account State

    func makeAccountStateStorage(for userWalletId: UserWalletId) -> ExpandableAccountItemStateStorage {
        AccountStateStorage(userWalletId: userWalletId, innerStorage: self)
    }

    // MARK: - Cleanup

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
                .prepend([])
                .pairwise()
                .receiveOnMain()
                .withWeakCaptureOf(self)
                .sink { storage, input in
                    storage.handleCryptoAccounts(
                        oldCryptoAccounts: input.0,
                        newCryptoAccounts: input.1,
                        userWalletId: userWalletId
                    )
                }
        }
    }

    private func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(let userWalletIds, _):
            handleDeletedUserWalletModels(userWalletIds)
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

    private func handleDeletedUserWalletModels(_ userWalletIds: [UserWalletId]) {
        for userWalletId in userWalletIds {
            let storageKeyPrefix = ExpandableAccountItemStateStorageKeyHelper.makeStorageKeyPrefix(
                userWalletId: userWalletId
            )

            accountStates.removeAll { $0.key.hasPrefix(storageKeyPrefix) }
            walletOpenStates.removeValue(forKey: userWalletId)
            userWalletModelsSubscriptions.removeValue(forKey: userWalletId)

            if selectedWalletId == userWalletId {
                selectedWalletId = nil
            }
        }
    }

    private func handleCryptoAccounts(
        oldCryptoAccounts: [CryptoAccounts],
        newCryptoAccounts: [CryptoAccounts],
        userWalletId: UserWalletId
    ) {
        let newIds = mapToPersistentIdentifiers(newCryptoAccounts)
        let newIdsFilter = newIds
            .map { $0.toPersistentIdentifier().toAnyHashable() }
            .toSet()

        let removedIds = mapToPersistentIdentifiers(oldCryptoAccounts)
            .filter { !newIdsFilter.contains($0.toPersistentIdentifier().toAnyHashable()) }

        for accountId in removedIds {
            let storageKey = ExpandableAccountItemStateStorageKeyHelper.makeStorageKey(
                accountId: accountId,
                userWalletId: userWalletId
            )
            accountStates.removeValue(forKey: storageKey)
        }
    }

    private func mapToPersistentIdentifiers(_ cryptoAccounts: [CryptoAccounts]) -> [any AccountModelPersistentIdentifierConvertible] {
        cryptoAccounts
            .reduce(into: [any CryptoAccountModel]()) { partialResult, element in
                switch element {
                case .single(let account):
                    partialResult.append(account)
                case .multiple(let accounts):
                    partialResult.append(contentsOf: accounts)
                }
            }
            .map { $0.id as (any AccountModelPersistentIdentifierConvertible) }
    }
}

// MARK: - Initializable

extension SwapTokenSelectorExpandedStateStorage: Initializable {
    func initialize() {
        subscribeToUserWalletModelsIfNeeded(userWalletRepository.models)
        bind()
    }
}

// MARK: - AccountStateStorage

private extension SwapTokenSelectorExpandedStateStorage {
    struct AccountStateStorage: ExpandableAccountItemStateStorage {
        var didUpdatePublisher: AnyPublisher<Void, Never> { .empty }

        private let userWalletId: UserWalletId
        private let storage: SwapTokenSelectorExpandedStateStorage

        init(userWalletId: UserWalletId, innerStorage: SwapTokenSelectorExpandedStateStorage) {
            self.userWalletId = userWalletId
            storage = innerStorage
        }

        func isExpanded(_ accountModel: some BaseAccountModel) -> Bool {
            let key = ExpandableAccountItemStateStorageKeyHelper.makeStorageKey(
                accountId: accountModel.id,
                userWalletId: userWalletId
            )
            return storage.accountStates[key] ?? false
        }

        func setIsExpanded(_ isExpanded: Bool, for accountModel: some BaseAccountModel) {
            let key = ExpandableAccountItemStateStorageKeyHelper.makeStorageKey(
                accountId: accountModel.id,
                userWalletId: userWalletId
            )
            storage.accountStates[key] = isExpanded
        }
    }

    enum StorageKeys: String, RawRepresentable {
        case accountStates = "tangem_expandable_swap_wallet_account_item_state_storage"
        case selectedWalletId = "tangem_swap_token_selector_selected_wallet_id"
    }
}

// MARK: - Injection

extension InjectedValues {
    var swapTokenSelectorExpandedStateStorage: SwapTokenSelectorExpandedStateStorage {
        get { Self[SwapTokenSelectorExpandedStateStorage.Key.self] }
        set { Self[SwapTokenSelectorExpandedStateStorage.Key.self] = newValue }
    }
}

private extension SwapTokenSelectorExpandedStateStorage {
    struct Key: InjectionKey {
        static var currentValue: SwapTokenSelectorExpandedStateStorage = .init()
    }
}
