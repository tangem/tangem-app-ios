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
    private let storage: CryptoAccountsPersistentStorage & _CryptoAccountsPersistentStorage
    private let storageDidUpdateSubject: StorageDidUpdateSubject

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var _cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> = storageDidUpdateSubject
        .prepend(())
        .withWeakCaptureOf(self)
        .map { $0.0.storage.getList() }
        .share(replay: 1)
        .eraseToAnyPublisher()

    init(
        tokenItemsRepository: TokenItemsRepository,
        networkService: CryptoAccountsNetworkService,
        storage: CryptoAccountsPersistentStorage & _CryptoAccountsPersistentStorage
    ) {
        storageDidUpdateSubject = StorageDidUpdateSubject()
        self.tokenItemsRepository = tokenItemsRepository
        self.networkService = networkService
        self.storage = storage
        storage.bind(to: storageDidUpdateSubject)
    }

    private func addCryptoAccount(withConfig config: CryptoAccountPersistentConfig, tokens: [StoredCryptoAccount.StoredToken]) {
        let storedAccount = StoredCryptoAccount(
            derivationIndex: config.derivationIndex,
            name: config.name,
            icon: .init(iconName: config.iconName, iconColor: config.iconColor),
            tokens: tokens,
            grouping: Constants.defaultGroupingType, // [REDACTED_TODO_COMMENT]
            sorting: Constants.defaultSortingType // [REDACTED_TODO_COMMENT]
        )
        storage.appendNewOrUpdateExisting(account: storedAccount)
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
        storage.getList().count
    }

    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> {
        _cryptoAccountsPublisher
    }

    func initialize(forUserWalletWithId userWalletId: UserWalletId) {
        if storage.isMigrationNeeded() {
            migrateStorage(forUserWalletWithId: userWalletId)
        }
    }

    func addCryptoAccount(withConfig config: CryptoAccountPersistentConfig, tokens: [TokenItem]) {
        // [REDACTED_TODO_COMMENT]
        let storedTokens: [StoredCryptoAccount.StoredToken] = []
        addCryptoAccount(withConfig: config, tokens: storedTokens)
    }

    func removeCryptoAccount(withIdentifier identifier: AnyHashable) {
        storage.removeAll { $0.derivationIndex.toAnyHashable() == identifier }
    }
}

// MARK: - Constants

private extension CommonCryptoAccountsRepository {
    enum Constants {
        static let defaultGroupingType: StoredCryptoAccount.Grouping = .none
        static let defaultSortingType: StoredCryptoAccount.Sorting = .manual
    }
}
