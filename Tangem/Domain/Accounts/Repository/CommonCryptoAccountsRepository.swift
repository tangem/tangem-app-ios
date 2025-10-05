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
    private let pendingStateHolder: PendingStateHolder

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var _cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> = storageDidUpdateSubject
        .prepend(())
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { $0.0.persistentStorage.getList() }
        .share(replay: 1)
        .eraseToAnyPublisher()

    private let hasTokenSynchronization: Bool

    private var loadAccountsSubscription: AnyCancellable?
    private var saveAccountsSubscription: AnyCancellable?

    init(
        tokenItemsRepository: TokenItemsRepository,
        networkService: CryptoAccountsNetworkService,
        persistentStorage: CryptoAccountsPersistentStorage,
        storageController: CryptoAccountsPersistentStorageController,
        hasTokenSynchronization: Bool
    ) {
        storageDidUpdateSubject = .init()
        pendingStateHolder = .init()
        self.tokenItemsRepository = tokenItemsRepository
        self.networkService = networkService
        self.persistentStorage = persistentStorage
        self.storageController = storageController
        self.hasTokenSynchronization = hasTokenSynchronization
        storageController.bind(to: storageDidUpdateSubject)
    }

    private func migrateStorage(forUserWalletWithId userWalletId: UserWalletId) {
        let mainAccountPersistentConfig = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let legacyStoredTokens = tokenItemsRepository.getList().entries
        let tokens = LegacyStorableEntriesConverter.convert(legacyStoredTokens: legacyStoredTokens)

        addCryptoAccount(withConfig: mainAccountPersistentConfig, tokens: tokens)
    }

    private func updateAccountsOnServer(cryptoAccounts: [StoredCryptoAccount]? = nil, completion: Completion? = nil) {
        guard hasTokenSynchronization else {
            completion?(.success(()))
            return
        }

        saveAccountsSubscription = runTask(in: self) { repository in
            let cryptoAccounts = cryptoAccounts ?? repository.persistentStorage.getList()
            do {
                try await repository.networkService.save(cryptoAccounts: cryptoAccounts)
                try Task.checkCancellation()
                await runOnMain { completion?(.success(())) }
            } catch CryptoAccountsNetworkServiceError.missingRevision {
                // [REDACTED_TODO_COMMENT]
            } catch CryptoAccountsNetworkServiceError.inconsistentState {
                // [REDACTED_TODO_COMMENT]
            } catch CryptoAccountsNetworkServiceError.noAccountsCreated {
                // [REDACTED_TODO_COMMENT]
            } catch CryptoAccountsNetworkServiceError.underlyingError(let error) {
                await repository.handleFailedUpdateAccountsOnServer(cryptoAccounts: cryptoAccounts, error: error, completion: completion)
            } catch {
                await repository.handleFailedUpdateAccountsOnServer(cryptoAccounts: cryptoAccounts, error: error, completion: completion)
            }
        }.eraseToAnyCancellable()
    }

    private func handleFailedUpdateAccountsOnServer(
        cryptoAccounts: [StoredCryptoAccount],
        error: Error,
        completion: Completion?
    ) async {
        guard !error.isCancellationError else {
            return
        }

        await pendingStateHolder.performIsolated { holder in
            guard !Task.isCancelled else {
                return
            }

            holder.cryptoAccountsToUpdate = cryptoAccounts
        }

        guard !Task.isCancelled else {
            return
        }

        await runOnMain { completion?(.failure(error)) }
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

    // [REDACTED_TODO_COMMENT]
    func addCryptoAccount(withConfig config: CryptoAccountPersistentConfig, tokens: [StoredCryptoAccount.Token]) {
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
                    // By definition, all legacy tokens currently stored are known
                    blockchainNetwork: .known(blockchainNetwork: entry.blockchainNetwork),
                    contractAddress: entry.contractAddress
                )
            }
        }
    }

    actor PendingStateHolder {
        var cryptoAccountsToUpdate: [StoredCryptoAccount]?
    }
}
