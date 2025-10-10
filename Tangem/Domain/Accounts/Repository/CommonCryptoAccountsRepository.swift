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
    private typealias StorageDidUpdateSubject = PassthroughSubject<Void, Never>

    private let tokenItemsRepository: TokenItemsRepository
    private let networkService: CryptoAccountsNetworkService
    private let persistentStorage: CryptoAccountsPersistentStorage
    private let storageController: CryptoAccountsPersistentStorageController
    private let storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var _cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> = storageDidUpdateSubject
        .prepend(())
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { $0.0.persistentStorage.getList() }
        .share(replay: 1)
        .eraseToAnyPublisher()

    init(
        tokenItemsRepository: TokenItemsRepository,
        networkService: CryptoAccountsNetworkService,
        persistentStorage: CryptoAccountsPersistentStorage,
        storageController: CryptoAccountsPersistentStorageController
    ) {
        storageDidUpdateSubject = .init()
        self.tokenItemsRepository = tokenItemsRepository
        self.networkService = networkService
        self.persistentStorage = persistentStorage
        self.storageController = storageController
        storageController.bind(to: storageDidUpdateSubject)
    }

    private func addCryptoAccount(withConfig config: CryptoAccountPersistentConfig, tokens: [StoredCryptoAccount.Token]) {
        let storedAccount = StoredCryptoAccount(
            derivationIndex: config.derivationIndex,
            name: config.name,
            icon: .init(iconName: config.iconName, iconColor: config.iconColor),
            tokens: tokens,
            grouping: Constants.defaultGroupingType, // [REDACTED_TODO_COMMENT]
            sorting: Constants.defaultSortingType // [REDACTED_TODO_COMMENT]
        )
        persistentStorage.appendNewOrUpdateExisting(account: storedAccount)
    }

    private func migrateStorage(forUserWalletWithId userWalletId: UserWalletId) {
        let mainAccountPersistentConfig = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let legacyStoredTokens = tokenItemsRepository.getList().entries
        let tokens = LegacyStorableEntriesConverter.convert(legacyStoredTokens: legacyStoredTokens)

        addCryptoAccount(withConfig: mainAccountPersistentConfig, tokens: tokens)
    }
}

// MARK: - CryptoAccountsRepository protocol conformance

extension CommonCryptoAccountsRepository: CryptoAccountsRepository {
    var totalCryptoAccountsCount: Int {
        persistentStorage.getList().count
    }

    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> {
        _cryptoAccountsPublisher
    }

    func initialize(forUserWalletWithId userWalletId: UserWalletId) {
        if storageController.isMigrationNeeded() {
            migrateStorage(forUserWalletWithId: userWalletId)
        }
    }

    func addCryptoAccount(withConfig config: CryptoAccountPersistentConfig, tokens: [TokenItem]) {
        // [REDACTED_TODO_COMMENT]
        let storedTokens: [StoredCryptoAccount.Token] = []
        addCryptoAccount(withConfig: config, tokens: storedTokens)
    }

    func removeCryptoAccount<T: Hashable>(withIdentifier identifier: T) {
        persistentStorage.removeAll { $0.derivationIndex.toAnyHashable() == identifier.toAnyHashable() }
    }
}

// MARK: - Constants

private extension CommonCryptoAccountsRepository {
    enum Constants {
        static let defaultGroupingType: StoredCryptoAccount.Grouping = .none
        static let defaultSortingType: StoredCryptoAccount.Sorting = .manual
    }
}

// MARK: - Auxiliary types

private extension CommonCryptoAccountsRepository {
    enum LegacyStorableEntriesConverter {
        static func convert(legacyStoredTokens: [StoredUserTokenList.Entry]) -> [StoredCryptoAccount.Token] {
            return legacyStoredTokens.map { entry in
                StoredCryptoAccount.Token(
                    id: entry.id,
                    name: entry.name,
                    symbol: entry.symbol,
                    decimalCount: entry.decimalCount,
                    blockchainNetwork: .known(blockchainNetwork: entry.blockchainNetwork),
                    contractAddress: entry.contractAddress
                )
            }
        }
    }
}
