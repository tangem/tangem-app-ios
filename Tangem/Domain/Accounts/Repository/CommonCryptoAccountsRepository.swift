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

    func updateCryptoAccount<T, each U>(
        withID id: T.ID,
        updates: repeat KeyPath<T, each U>
    ) where T: CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
    }

    func addCryptoAccount(_ cryptoAccountModel: any CryptoAccountModel) {
        // [REDACTED_TODO_COMMENT]
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
                return fetch()
            }
        }

        func remove(account: StoredCryptoAccount) {
            // This combined read-write operation must be atomic, hence the barrier flag
            workingQueue.async(flags: .barrier) {
                var currentItems = self.fetch()
                // Every wallet has its own storage, therefore account uniqueness is guaranteed by derivation index
                currentItems.removeAll(where: { $0.derivationIndex == account.derivationIndex })
                self.save(currentItems)
            }
        }

        func removeAll() {
            workingQueue.async(flags: .barrier) {
                self.save([])
            }
        }

        private func fetch() -> [StoredCryptoAccount] {
            return (try? persistentStorage.value(for: key)) ?? []
        }

        private func save(_ items: [StoredCryptoAccount]) {
            do {
                try persistentStorage.store(value: items, for: key)
                storageDidUpdateSubject.send()
            } catch {
                assertionFailure("CommonCryptoAccountsRepository.Storage saving error: \(error)")
            }
        }
    }
}
