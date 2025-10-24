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
import TangemNetworkUtils

final class CommonCryptoAccountsRepository {
    private typealias StorageDidUpdatePublisher = AnyPublisher<[StoredCryptoAccount], Never>

    @available(iOS, deprecated: 100000.0, message: "For migration purposes only. Will be removed later ([REDACTED_INFO])")
    private let tokenItemsRepository: TokenItemsRepository
    private let defaultAccountFactory: DefaultAccountFactory
    private let networkService: CryptoAccountsNetworkService
    private let persistentStorage: CryptoAccountsPersistentStorage
    private let storageController: CryptoAccountsPersistentStorageController
    private let storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject
    private let pendingStateHolder: PendingStateHolder

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var storageDidUpdatePublisher: StorageDidUpdatePublisher = storageDidUpdateSubject
        .prepend(()) // An initial value to trigger loading from storage
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { $0.0.persistentStorage.getList() }
        .removeDuplicates()
        .share(replay: 1)
        .eraseToAnyPublisher()

    /// Bool flag for migration of custom tokens to tokens form our API.
    /// Migration is performed once per app launch for every unique wallet.
    private var areCustomTokensMigrated = false
    private let hasTokenSynchronization: Bool

    private var loadAccountsSubscription: AnyCancellable?
    private var saveAccountsSubscription: AnyCancellable?
    private var storageDidUpdateSubscription: AnyCancellable?

    init(
        tokenItemsRepository: TokenItemsRepository,
        defaultAccountFactory: DefaultAccountFactory,
        networkService: CryptoAccountsNetworkService,
        persistentStorage: CryptoAccountsPersistentStorage,
        storageController: CryptoAccountsPersistentStorageController,
        hasTokenSynchronization: Bool
    ) {
        storageDidUpdateSubject = .init()
        pendingStateHolder = .init()
        self.tokenItemsRepository = tokenItemsRepository
        self.defaultAccountFactory = defaultAccountFactory
        self.networkService = networkService
        self.persistentStorage = persistentStorage
        self.storageController = storageController
        self.hasTokenSynchronization = hasTokenSynchronization
        storageController.bind(to: storageDidUpdateSubject)
    }

    // [REDACTED_TODO_COMMENT]
    private func migrateStorage(forUserWalletWithId userWalletId: UserWalletId) {
        let mainAccountPersistentConfig = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let legacyStoredTokens = tokenItemsRepository.getList().entries
        let tokens = LegacyStorableEntriesConverter.convert(legacyStoredTokens: legacyStoredTokens)
        let newCryptoAccount = StoredCryptoAccount(config: mainAccountPersistentConfig, tokens: tokens)

        persistentStorage.appendNewOrUpdateExisting(account: newCryptoAccount)
    }

    // MARK: - Loading accounts and tokens from server

    private func loadAccountsFromServer(_ completion: @escaping UserTokensRepository.Completion) {
        loadAccountsSubscription = runTask(in: self) { repository in
            let hasScheduledPendingUpdate = await repository.pendingStateHolder.performIsolated { holder in
                guard
                    let pending = holder.cryptoAccountsToUpdate,
                    !Task.isCancelled
                else {
                    return false
                }

                holder.cryptoAccountsToUpdate = nil
                repository.updateAccountsOnServer(cryptoAccounts: pending, completion: completion)

                return true
            }

            guard
                !hasScheduledPendingUpdate,
                !Task.isCancelled
            else {
                return
            }

            do {
                try await repository.loadAccountsFromServerAsync()
                await runOnMainIfNotCancelled { completion(.success(())) }
            } catch {
                await repository.handleFailedLoadingAccountsFromServer(error: error, completion: completion)
            }
        }.eraseToAnyCancellable()
    }

    private func loadAccountsFromServerAsync() async throws {
        do {
            let remoteCryptoAccountsInfo = try await networkService.getCryptoAccounts()
            try Task.checkCancellation()

            var updatedAccounts = remoteCryptoAccountsInfo.accounts
            let shouldUpdateTokenList = StoredCryptoAccountsTokensDistributor.distributeTokens(
                in: &updatedAccounts,
                additionalTokens: remoteCryptoAccountsInfo.legacyTokens
            )

            // Updating the local storage first since it's the primary purpose of this method
            persistentStorage.appendNewOrUpdateExisting(accounts: updatedAccounts)

            if shouldUpdateTokenList {
                try await updateAccountsOnServerAsync(cryptoAccounts: updatedAccounts)
            }
        } catch CryptoAccountsNetworkServiceError.missingRevision, CryptoAccountsNetworkServiceError.inconsistentState {
            // Impossible case, since we don't update remote accounts here
            preconditionFailure("Unexpected state: missing revision or inconsistent state when loading accounts from server")
        } catch CryptoAccountsNetworkServiceError.noAccountsCreated {
            let defaultAccount = defaultAccountFactory.makeDefaultAccount()
            try await addAccountsInternal([defaultAccount]) // Explicitly creates a new account if none exist on the server yet
        } catch CryptoAccountsNetworkServiceError.underlyingError(let error) {
            throw error
        }
    }

    private func handleFailedLoadingAccountsFromServer(error: Error, completion: UserTokensRepository.Completion) async {
        guard !error.isCancellationError else {
            return
        }

        await runOnMainIfNotCancelled { completion(.failure(error)) }
    }

    // MARK: - Updating accounts and tokens on server

    private func updateAccountsOnServer(cryptoAccounts: [StoredCryptoAccount]? = nil, completion: UserTokensRepository.Completion? = nil) {
        guard hasTokenSynchronization else {
            completion?(.success(()))
            return
        }

        saveAccountsSubscription = runTask(in: self) { repository in
            let cryptoAccounts = cryptoAccounts ?? repository.persistentStorage.getList()

            do {
                try await repository.updateAccountsOnServerAsync(cryptoAccounts: cryptoAccounts)
                await runOnMainIfNotCancelled { completion?(.success(())) }
            } catch {
                await repository.handleFailedUpdateAccountsOnServer(cryptoAccounts: cryptoAccounts, error: error, completion: completion)
            }
        }.eraseToAnyCancellable()
    }

    private func updateAccountsOnServerAsync(cryptoAccounts: [StoredCryptoAccount]) async throws {
        do {
            // [REDACTED_TODO_COMMENT]
            try await networkService.saveAccounts(from: cryptoAccounts)
            try await networkService.saveTokens(from: cryptoAccounts)
        } catch CryptoAccountsNetworkServiceError.missingRevision, CryptoAccountsNetworkServiceError.inconsistentState {
            try await refreshInconsistentState(retryCount: Constants.maxRetryCount)
            try Task.checkCancellation()
            try await updateAccountsOnServerAsync(cryptoAccounts: cryptoAccounts) // Schedules a retry after fixing the state
        } catch CryptoAccountsNetworkServiceError.noAccountsCreated {
            try await loadAccountsFromServerAsync() // Implicitly creates a new account if none exist on the server yet
        } catch CryptoAccountsNetworkServiceError.underlyingError(let error) {
            throw error
        }
    }

    private func handleFailedUpdateAccountsOnServer(
        cryptoAccounts: [StoredCryptoAccount],
        error: Error,
        completion: UserTokensRepository.Completion?
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

        await runOnMainIfNotCancelled { completion?(.failure(error)) }
    }

    private func refreshInconsistentState(retryCount: Int) async throws {
        var currentRetryAttempt = 0
        var lastError: Error?

        while currentRetryAttempt < retryCount {
            do {
                let retryInterval = ExponentialBackoffInterval(retryAttempt: currentRetryAttempt)
                try await Task.sleep(nanoseconds: retryInterval())

                _ = try await networkService.getCryptoAccounts() // Implicitly refreshes the revision (i.e. the `ETag` header)
                try Task.checkCancellation()
            } catch let error as CryptoAccountsNetworkServiceError where error.isCancellationError {
                break
            } catch {
                lastError = error
                currentRetryAttempt += 1
            }
        }

        if let lastError {
            throw lastError
        }
    }

    // MARK: - Accounts and tokens adding

    func addAccountsInternal(_ accounts: [StoredCryptoAccount]) async throws {
        let remoteCryptoAccountsInfo = try await networkService.saveAccounts(from: accounts)
        try Task.checkCancellation()

        var updatedAccounts = remoteCryptoAccountsInfo.accounts
        let shouldUpdateTokenList = StoredCryptoAccountsTokensDistributor.distributeTokens(
            in: &updatedAccounts,
            additionalTokens: remoteCryptoAccountsInfo.legacyTokens
        )

        if shouldUpdateTokenList {
            try await networkService.saveTokens(from: updatedAccounts)
        }

        // Updating local storage only after successful remote update
        persistentStorage.appendNewOrUpdateExisting(accounts: updatedAccounts)
    }

    // MARK: - Custom tokens upgrade and migration

    private func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        // [REDACTED_TODO_COMMENT]
        fatalError("\(#function) not implemented yet!")
    }
}

// MARK: - CryptoAccountsRepository protocol conformance

extension CommonCryptoAccountsRepository: CryptoAccountsRepository {
    var totalCryptoAccountsCount: Int {
        persistentStorage.getList().count
    }

    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> {
        storageDidUpdatePublisher
            .eraseToAnyPublisher()
    }

    func initialize(forUserWalletWithId userWalletId: UserWalletId) {
        if storageController.isMigrationNeeded() {
            migrateStorage(forUserWalletWithId: userWalletId)
        }
    }

    func getRemoteState() async throws -> CryptoAccountsRemoteState {
        let cryptoAccounts = try await networkService.getCryptoAccounts()
        try Task.checkCancellation()

        return CryptoAccountsRemoteState(
            nextDerivationIndex: cryptoAccounts.nextDerivationIndex,
            accounts: cryptoAccounts.accounts
        )
    }

    func addNewCryptoAccount(withConfig config: CryptoAccountPersistentConfig, remoteState: CryptoAccountsRemoteState) async throws {
        let newCryptoAccount = StoredCryptoAccount(config: config)
        var existingAccounts = remoteState.accounts
        existingAccounts.append(newCryptoAccount)
        try await addAccountsInternal(existingAccounts)
    }

    func updateExistingCryptoAccount(withConfig config: CryptoAccountPersistentConfig) {
        // [REDACTED_TODO_COMMENT]
    }

    func removeCryptoAccount<T: Hashable>(withIdentifier identifier: T) {
        persistentStorage.removeAll { $0.derivationIndex.toAnyHashable() == identifier.toAnyHashable() }
    }
}

// MARK: - Auxiliary types

private extension CommonCryptoAccountsRepository {
    actor PendingStateHolder {
        var cryptoAccountsToUpdate: [StoredCryptoAccount]?
    }

    @available(iOS, deprecated: 100000.0, message: "For migration purposes only. Will be removed later ([REDACTED_INFO])")
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
}

// MARK: - Constants

private extension CommonCryptoAccountsRepository {
    enum Constants {
        static let maxRetryCount = 3
    }
}

// MARK: - Convenience extensions

@MainActor
private func runOnMainIfNotCancelled(_ code: () throws -> Void) rethrows {
    if !Task.isCancelled {
        try code()
    }
}
