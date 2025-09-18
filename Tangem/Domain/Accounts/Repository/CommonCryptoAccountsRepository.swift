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
        let storedTokens = tokenItemsRepository.getList().entries

        addCryptoAccount(withConfig: mainAccountPersistentConfig, tokens: storedTokens)
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

    func removeCryptoAccount(withIdentifier identifier: AnyHashable) {
        persistentStorage.removeAll { $0.derivationIndex.toAnyHashable() == identifier }
    }
}

// MARK: - Constants

private extension CommonCryptoAccountsRepository {
    enum Constants {
        static let defaultGroupingType: StoredCryptoAccount.Grouping = .none
        static let defaultSortingType: StoredCryptoAccount.Sorting = .manual
    }
}
