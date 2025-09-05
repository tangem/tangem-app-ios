//
//  CommonCryptoAccountsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class CommonCryptoAccountsRepository {
    fileprivate typealias StorageDidUpdateSubject = PassthroughSubject<Void, Never>

    private let userWalletId: UserWalletId
    private let tokenItemsRepository: TokenItemsRepository
    private let networkService: CryptoAccountsService
    private let storage: Storage
    private let storageDidUpdateSubject: StorageDidUpdateSubject

    private lazy var _cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> = storageDidUpdateSubject
        .withWeakCaptureOf(self)
        .map { $0.0.storage.getList() }
        .share(replay: 1)
        .eraseToAnyPublisher()

    init(
        userWalletId: UserWalletId,
        tokenItemsRepository: TokenItemsRepository,
        networkService: CryptoAccountsService
    ) {
        let storageDidUpdateSubject = StorageDidUpdateSubject()
        self.storageDidUpdateSubject = storageDidUpdateSubject
        self.userWalletId = userWalletId
        self.tokenItemsRepository = tokenItemsRepository
        self.networkService = networkService
        storage = Storage(
            storageIdentifier: userWalletId.stringValue,
            storageDidUpdateSubject: storageDidUpdateSubject
        )
    }
}

// MARK: - CryptoAccountsRepository protocol conformance

extension CommonCryptoAccountsRepository: CryptoAccountsRepository {
    var totalCryptoAccountsCount: Int {
        storage.getList().count
    }

    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> {
        _cryptoAccountsPublisher
    }

    func initialize() {
        // [REDACTED_TODO_COMMENT]
    }

    func addCryptoAccount(withConfig config: CryptoAccountPersistentConfig, tokens: [TokenItem]) {
        let storedAccount = StoredCryptoAccount(
            derivationIndex: config.derivationIndex,
            name: config.name,
            icon: .init(iconName: config.iconName, iconColor: config.iconColor),
            tokenList: .empty // [REDACTED_TODO_COMMENT]
        )
        storage.appendNewOrUpdateExisting(account: storedAccount)
    }

    func removeCryptoAccount(withIdentifier identifier: AnyHashable) {
        storage.remove { storedCryptoAccount in
            AnyHashable(storedCryptoAccount.derivationIndex) == identifier
        }
    }
}

// MARK: - Constants

// [REDACTED_TODO_COMMENT]
/** private */ extension CommonCryptoAccountsRepository {
    enum Constants {
        static let mainAccountDerivationIndex = 0
        static let mainAccountName = "Main Account" // [REDACTED_TODO_COMMENT]
        static let mainAccountIconName = AccountModel.Icon.Name.star.rawValue
        static let mainAccountIconColor = AccountModel.Icon.Color.brightBlue.rawValue
    }
}

// MARK: - Auxiliary types

private extension CommonCryptoAccountsRepository {
    // [REDACTED_TODO_COMMENT]
    final class Storage {
        @Injected(\.persistentStorage) private var persistentStorage: PersistentStorageProtocol

        private let key: PersistentStorageKey
        private let workingQueue: DispatchQueue
        private let storageDidUpdateSubject: StorageDidUpdateSubject

        init(
            storageIdentifier: String,
            storageDidUpdateSubject: StorageDidUpdateSubject
        ) {
            key = .accounts(cid: storageIdentifier)
            self.storageDidUpdateSubject = storageDidUpdateSubject
            workingQueue = DispatchQueue(
                label: "com.tangem.CommonCryptoAccountsRepository.Storage.workingQueue_\(storageIdentifier)",
                attributes: .concurrent,
                target: .global(qos: .userInitiated)
            )
        }

        func getList() -> [StoredCryptoAccount] {
            workingQueue.sync {
                return unsafeFetch()
            }
        }

        func appendNewOrUpdateExisting(account: StoredCryptoAccount) {
            workingQueue.async(flags: .barrier) {
                var editedItems = self.unsafeFetch()
                var isDirty = false

                if let targetIndex = editedItems.firstIndex(where: { $0.derivationIndex == account.derivationIndex }) {
                    isDirty = editedItems[targetIndex] != account
                    editedItems[targetIndex] = account
                } else {
                    isDirty = true
                    editedItems.append(account)
                }

                if isDirty {
                    self.unsafeSave(editedItems)
                }
            }
        }

        func remove(accountUsingPredicate predicate: @escaping (StoredCryptoAccount) -> Bool) {
            // This combined read-write operation must be atomic, hence the barrier flag
            workingQueue.async(flags: .barrier) {
                let currentItems = self.unsafeFetch()
                var editedItems = currentItems

                editedItems.removeAll(where: predicate)
                let isDirty = editedItems.count != currentItems.count

                if isDirty {
                    self.unsafeSave(editedItems)
                }
            }
        }

        func removeAll() {
            workingQueue.async(flags: .barrier) {
                self.unsafeSave([])
            }
        }

        /// Unsafe because it must be called from `workingQueue` only.
        private func unsafeFetch() -> [StoredCryptoAccount] {
            return (try? persistentStorage.value(for: key)) ?? []
        }

        /// Unsafe because it must be called from `workingQueue` only.
        private func unsafeSave(_ items: [StoredCryptoAccount]) {
            do {
                try persistentStorage.store(value: items, for: key)
                storageDidUpdateSubject.send()
            } catch {
                assertionFailure("CommonCryptoAccountsRepository.Storage saving error: \(error)")
            }
        }
    }
}
