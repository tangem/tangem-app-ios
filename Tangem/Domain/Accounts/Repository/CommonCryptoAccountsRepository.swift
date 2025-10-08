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
import UIKit // [REDACTED_TODO_COMMENT]

// [REDACTED_TODO_COMMENT]
enum StoredCryptoAccountsMerger {
    static func merge(
        oldAccounts: [StoredCryptoAccount],
        newAccounts: [StoredCryptoAccount]
    ) -> (accounts: [StoredCryptoAccount], isDirty: Bool) {
        var editedAccounts = oldAccounts
        var isDirty = false

        for newAccount in newAccounts {
            if let targetIndex = oldAccounts.firstIndex(where: { $0.derivationIndex == newAccount.derivationIndex }) {
                isDirty = editedAccounts[targetIndex] != newAccount
                editedAccounts[targetIndex] = newAccount
            } else {
                isDirty = true
                editedAccounts.append(newAccount)
            }
        }

        return (editedAccounts, isDirty)
    }
}

final class CommonCryptoAccountsRepository {
    private typealias StorageDidUpdateSubject = PassthroughSubject<Void, Never>
    private typealias StorageDidUpdatePublisher = AnyPublisher<(accounts: [StoredCryptoAccount], isSilent: Bool), Never>

    private let tokenItemsRepository: TokenItemsRepository
    private let networkService: CryptoAccountsNetworkService
    private let persistentStorage: CryptoAccountsPersistentStorage
    private let storageController: CryptoAccountsPersistentStorageController
    private let storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject
    private let pendingStateHolder: PendingStateHolder

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var storageDidUpdatePublisher: StorageDidUpdatePublisher = storageDidUpdateSubject
        .prepend(true) // An initial value to trigger loading from storage, a silent one since no uploading needed
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { repository, isSilent in
            let accounts = repository.persistentStorage.getList()
            return (accounts, isSilent)
        }
        .removeDuplicates { $0.accounts == $1.accounts }
        .share(replay: 1)
        .eraseToAnyPublisher()

    private let hasTokenSynchronization: Bool

    private var loadAccountsSubscription: AnyCancellable?
    private var saveAccountsSubscription: AnyCancellable?
    private var storageDidUpdateSubscription: AnyCancellable?

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
        bind()
    }

    private func bind() {
        storageDidUpdateSubscription = storageDidUpdatePublisher
            .dropFirst() // Skip initial value added by `prepend` operator above
            .filter { !$0.isSilent }
            .debounce(for: 1.0, scheduler: DispatchQueue.main) // Debounce to avoid multiple remote updates
            .withWeakCaptureOf(self)
            .sink { repository, input in
                repository.updateAccountsOnServer(cryptoAccounts: input.accounts)
            }
    }

    private func migrateStorage(forUserWalletWithId userWalletId: UserWalletId) {
        let mainAccountPersistentConfig = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let legacyStoredTokens = tokenItemsRepository.getList().entries
        let tokens = LegacyStorableEntriesConverter.convert(legacyStoredTokens: legacyStoredTokens)
        let updates = AccountsUpdates(hasNewAccount: true, updates: [(mainAccountPersistentConfig, tokens)])

        addNewOrUpdateExistingCryptoAccounts(updates: updates)
    }

    private func updateAccountsOnServer(cryptoAccounts: [StoredCryptoAccount]? = nil, completion: _UserTokenListManager.Completion? = nil) {
        guard hasTokenSynchronization else {
            completion?(.success(()))
            return
        }

        saveAccountsSubscription = runTask(in: self) { repository in
            let cryptoAccounts = cryptoAccounts ?? repository.persistentStorage.getList()

            do {
                try await repository.updateAccountsOnServerAsync(cryptoAccounts: cryptoAccounts)
                try Task.checkCancellation()
                await runOnMain { completion?(.success(())) }
            } catch {
                await repository.handleFailedUpdateAccountsOnServer(cryptoAccounts: cryptoAccounts, error: error, completion: completion)
            }
        }.eraseToAnyCancellable()
    }

    private func updateAccountsOnServerAsync(cryptoAccounts: [StoredCryptoAccount]) async throws {
        do {
            try await networkService.save(cryptoAccounts: cryptoAccounts, updateType: .all) // [REDACTED_TODO_COMMENT]
            try Task.checkCancellation()
        } catch CryptoAccountsNetworkServiceError.missingRevision {
            // [REDACTED_TODO_COMMENT]
        } catch CryptoAccountsNetworkServiceError.inconsistentState {
            // [REDACTED_TODO_COMMENT]
        } catch CryptoAccountsNetworkServiceError.noAccountsCreated {
            // [REDACTED_TODO_COMMENT]
        } catch CryptoAccountsNetworkServiceError.underlyingError(let error) {
            throw error
        } catch {
            throw error
        }
    }

    private func handleFailedUpdateAccountsOnServer(
        cryptoAccounts: [StoredCryptoAccount],
        error: Error,
        completion: _UserTokenListManager.Completion?
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
        storageDidUpdatePublisher
            .map(\.accounts)
            .eraseToAnyPublisher()
    }

    func initialize(forUserWalletWithId userWalletId: UserWalletId) {
        if storageController.isMigrationNeeded() {
            migrateStorage(forUserWalletWithId: userWalletId)
        }
    }

    func getRemoteState() async throws -> CryptoAccountsRemoteState {
        let cryptoAccounts = try await networkService.getCryptoAccounts()

        return CryptoAccountsRemoteState(
            nextDerivationIndex: cryptoAccounts.nextDerivationIndex,
            accounts: cryptoAccounts.accounts
        )
    }

    func addNewOrUpdateExistingCryptoAccounts(updates: AccountsUpdates) async throws {
        let storedAccounts = updates.updates.map { update in
            StoredCryptoAccount(
                derivationIndex: update.config.derivationIndex,
                name: update.config.name,
                icon: .init(iconName: update.config.iconName, iconColor: update.config.iconColor),
                tokens: update.tokens,
                grouping: Constants.defaultGroupingType, // [REDACTED_TODO_COMMENT]
                sorting: Constants.defaultSortingType // [REDACTED_TODO_COMMENT]
            )
        }

        // [REDACTED_TODO_COMMENT]
        if updates.hasNewAccount {
            // Updating local storage only after successful remote update and doing it silently to avoid multiple uploads
            try await updateAccountsOnServerAsync(cryptoAccounts: storedAccounts)
            persistentStorage.addNewOrUpdateExisting(accounts: storedAccounts, silent: true)
        } else {
            // Updating local storage which in turn will trigger remote update
            persistentStorage.addNewOrUpdateExisting(accounts: storedAccounts, silent: false)
        }
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
