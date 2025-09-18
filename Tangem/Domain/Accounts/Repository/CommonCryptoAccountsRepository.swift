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
    private let tokenItemsRepository: TokenItemsRepository
    private let networkService: CryptoAccountsNetworkService
    private let storage: CryptoAccountsPersistentStorage
    private let storageDidUpdateSubject: CryptoAccountsPersistentStorage.StorageDidUpdateSubject

    private lazy var _cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> = storageDidUpdateSubject
        .withWeakCaptureOf(self)
        .map { $0.0.storage.getList() }
        .share(replay: 1)
        .eraseToAnyPublisher()

    init(
        tokenItemsRepository: TokenItemsRepository,
        networkService: CryptoAccountsNetworkService,
        storage: CryptoAccountsPersistentStorage
    ) {
        storageDidUpdateSubject = CryptoAccountsPersistentStorage.StorageDidUpdateSubject()
        self.tokenItemsRepository = tokenItemsRepository
        self.networkService = networkService
        self.storage = storage
        storage.bind(to: storageDidUpdateSubject)
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
        storage.removeAll { $0.derivationIndex.toAnyHashable() == identifier }
    }
}
