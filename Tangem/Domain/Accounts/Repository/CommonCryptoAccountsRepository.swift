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
    private let auxiliaryDataStorage: CryptoAccountsAuxiliaryDataStorage
    fileprivate let persistentStorage: CryptoAccountsPersistentStorage
    private let storageController: CryptoAccountsPersistentStorageController
    private let storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject
    private let pendingStateHolder: PendingStateHolder
    /// Implicitly unwrapped to resolve circular dependency
    fileprivate var debouncer: Debouncer<UserTokensRepository.Result>! // [REDACTED_TODO_COMMENT]

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var storageDidUpdatePublisher: StorageDidUpdatePublisher = storageDidUpdateSubject
        .prepend(()) // An initial value to trigger loading from storage
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .filter { !$0.0.storageController.isMigrationNeeded() } // Wait for migration to complete before emitting any values
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
        auxiliaryDataStorage: CryptoAccountsAuxiliaryDataStorage,
        persistentStorage: CryptoAccountsPersistentStorage,
        storageController: CryptoAccountsPersistentStorageController,
        hasTokenSynchronization: Bool
    ) {
        storageDidUpdateSubject = .init()
        pendingStateHolder = .init()
        self.tokenItemsRepository = tokenItemsRepository
        self.defaultAccountFactory = defaultAccountFactory
        self.networkService = networkService
        self.auxiliaryDataStorage = auxiliaryDataStorage
        self.persistentStorage = persistentStorage
        self.storageController = storageController
        self.hasTokenSynchronization = hasTokenSynchronization
        debouncer = Debouncer(interval: Constants.loadAccountsDebounceInterval) { [weak self] completion in
            self?.loadAccountsFromServer(completion)
        }
        storageController.bind(to: storageDidUpdateSubject)
    }

    // MARK: - Migration, not accounts created, no wallets created, etc.

    private func migrateStorage(forUserWalletWithId userWalletId: UserWalletId) {
        let mainAccountPersistentConfig = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let legacyStoredTokens = tokenItemsRepository.getList().entries
        let tokens = LegacyStoredEntryConverter.convert(legacyStoredTokens: legacyStoredTokens)
        let newCryptoAccount = StoredCryptoAccount(config: mainAccountPersistentConfig, tokens: tokens)

        persistentStorage.replace(with: [newCryptoAccount])
        auxiliaryDataStorage.totalAccountsCount = 1
    }

    private func addDefaultAccount(isWalletCreated: Bool) async throws {
        if !isWalletCreated {
            // [REDACTED_TODO_COMMENT]
        }
        let defaultAccount = defaultAccountFactory.makeDefaultAccount()
        try await addAccountsInternal([defaultAccount]) // Explicitly creates a new account if none exist on the server yet
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
                repository.updateAccountsOnServer(cryptoAccounts: pending, updateType: .all, completion: completion)

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
            if updatedAccounts.isEmpty {
                throw InternalError.migrationNeeded
            }

            let shouldUpdateTokenList = StoredCryptoAccountsTokensDistributor.distributeTokens(
                in: &updatedAccounts,
                additionalTokens: remoteCryptoAccountsInfo.legacyTokens
            )

            // Updating the local storage first since it's the primary purpose of this method
            persistentStorage.replace(with: updatedAccounts)
            auxiliaryDataStorage.archivedAccountsCount = remoteCryptoAccountsInfo.counters.archived
            auxiliaryDataStorage.totalAccountsCount = remoteCryptoAccountsInfo.counters.total

            if shouldUpdateTokenList {
                // Token distribution between accounts was performed therefore tokens need to be updated on the server
                try await updateAccountsOnServerAsync(cryptoAccounts: updatedAccounts, updateType: .tokens)
            }
        } catch CryptoAccountsNetworkServiceError.missingRevision, CryptoAccountsNetworkServiceError.inconsistentState {
            // Impossible case, since we don't update remote accounts here
            preconditionFailure("Unexpected state: missing revision or inconsistent state when loading accounts from server")
        } catch CryptoAccountsNetworkServiceError.underlyingError(let error) {
            throw error
        } catch CryptoAccountsNetworkServiceError.noAccountsCreated {
            try await addDefaultAccount(isWalletCreated: false)
        } catch InternalError.migrationNeeded {
            try await addDefaultAccount(isWalletCreated: true)
        }
    }

    private func handleFailedLoadingAccountsFromServer(error: Error, completion: UserTokensRepository.Completion) async {
        guard !error.isCancellationError else {
            return
        }

        await runOnMainIfNotCancelled { completion(.failure(error)) }
    }

    // MARK: - Updating accounts and tokens on server

    fileprivate func updateAccountsOnServer(
        cryptoAccounts: [StoredCryptoAccount]? = nil,
        updateType: RemoteUpdateType,
        completion: UserTokensRepository.Completion? = nil
    ) {
        guard hasTokenSynchronization else {
            completion?(.success(()))
            return
        }

        saveAccountsSubscription = runTask(in: self) { repository in
            let cryptoAccounts = cryptoAccounts ?? repository.persistentStorage.getList()

            do {
                try await repository.updateAccountsOnServerAsync(cryptoAccounts: cryptoAccounts, updateType: updateType)
                await runOnMainIfNotCancelled { completion?(.success(())) }
            } catch {
                await repository.handleFailedUpdateAccountsOnServer(cryptoAccounts: cryptoAccounts, error: error, completion: completion)
            }
        }.eraseToAnyCancellable()
    }

    private func updateAccountsOnServerAsync(cryptoAccounts: [StoredCryptoAccount], updateType: RemoteUpdateType) async throws {
        do {
            if updateType.contains(.accounts) {
                try await networkService.saveAccounts(from: cryptoAccounts)
            }
            if updateType.contains(.tokens) {
                try await networkService.saveTokens(from: cryptoAccounts)
            }
        } catch CryptoAccountsNetworkServiceError.missingRevision, CryptoAccountsNetworkServiceError.inconsistentState {
            try await refreshInconsistentState(retryCount: Constants.maxRetryCount)
            try Task.checkCancellation()
            try await updateAccountsOnServerAsync(cryptoAccounts: cryptoAccounts, updateType: updateType) // Schedules a retry after fixing the state
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
                lastError = nil // Clearing last error on success
                break
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

    // MARK: - Internal CRUD methods for accounts (always remote first, then local)

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
        persistentStorage.replace(with: updatedAccounts)
        auxiliaryDataStorage.archivedAccountsCount = remoteCryptoAccountsInfo.counters.archived
        auxiliaryDataStorage.totalAccountsCount = remoteCryptoAccountsInfo.counters.total
    }

    /// - Note: Unlike adding or updating accounts (using `addAccountsInternal` method),
    /// removing accounts doesn't require token distribution after updating the remote state.
    func removeAccountsInternal(_ identifier: some Hashable) async throws {
        var existingCryptoAccounts = persistentStorage.getList()
        existingCryptoAccounts.removeAll { $0.derivationIndex.toAnyHashable() == identifier.toAnyHashable() }

        let remoteCryptoAccountsInfo = try await networkService.saveAccounts(from: existingCryptoAccounts)
        try Task.checkCancellation()

        // Updating local storage only after successful remote update
        persistentStorage.removeAll { $0.derivationIndex.toAnyHashable() == identifier.toAnyHashable() }
        auxiliaryDataStorage.archivedAccountsCount = remoteCryptoAccountsInfo.counters.archived
        auxiliaryDataStorage.totalAccountsCount = remoteCryptoAccountsInfo.counters.total
    }

    // MARK: - Custom tokens upgrade and migration

    private func tryMigrateTokens() -> AnyPublisher<Void, Never> {
        // [REDACTED_TODO_COMMENT]
        fatalError("\(#function) not implemented yet!")
    }
}

// MARK: - CryptoAccountsRepository protocol conformance

extension CommonCryptoAccountsRepository: CryptoAccountsRepository {
    var cryptoAccountsPublisher: AnyPublisher<[StoredCryptoAccount], Never> {
        storageDidUpdatePublisher
            .eraseToAnyPublisher()
    }

    var auxiliaryDataPublisher: AnyPublisher<CryptoAccountsAuxiliaryData, Never> {
        auxiliaryDataStorage
            .didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { repository, _ in
                CryptoAccountsAuxiliaryData(
                    archivedAccountsCount: repository.auxiliaryDataStorage.archivedAccountsCount,
                    totalAccountsCount: repository.auxiliaryDataStorage.totalAccountsCount,
                )
            }
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
            nextDerivationIndex: cryptoAccounts.counters.total,
            accounts: cryptoAccounts.accounts
        )
    }

    func addNewCryptoAccount(withConfig config: CryptoAccountPersistentConfig, remoteState: CryptoAccountsRemoteState) async throws {
        let newCryptoAccount = StoredCryptoAccount(config: config)
        let existingCryptoAccounts = remoteState.accounts
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
        let (editedItems, isDirty) = merger.merge(oldAccounts: existingCryptoAccounts, newAccounts: [newCryptoAccount])

        if isDirty {
            try await addAccountsInternal(editedItems)
        }
    }

    func updateExistingCryptoAccount(withConfig config: CryptoAccountPersistentConfig) {
        let updatedCryptoAccount = StoredCryptoAccount(config: config)
        let existingCryptoAccounts = persistentStorage.getList()
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: true)
        let (editedItems, isDirty) = merger.merge(oldAccounts: existingCryptoAccounts, newAccounts: [updatedCryptoAccount])

        if isDirty {
            persistentStorage.appendNewOrUpdateExisting(editedItems)
            // No tokens distribution was performed here therefore only accounts need to be updated on the server
            updateAccountsOnServer(cryptoAccounts: editedItems, updateType: .accounts)
        }
    }

    func removeCryptoAccount(withIdentifier identifier: some Hashable) async throws {
        try await removeAccountsInternal(identifier)
    }
}

// MARK: - UserTokensRepository protocol adapter

/// An adapter to use `CommonCryptoAccountsRepository` as `UserTokensRepository`.
final class UserTokensRepositoryAdapter: UserTokensRepository {
    private let innerRepository: CommonCryptoAccountsRepository
    private let derivationIndex: Int

    init(
        innerRepository: CommonCryptoAccountsRepository,
        derivationIndex: Int
    ) {
        self.innerRepository = innerRepository
        self.derivationIndex = derivationIndex
    }

    var cryptoAccountPublisher: AnyPublisher<StoredCryptoAccount, Never> {
        innerRepository
            .cryptoAccountsPublisher
            // [REDACTED_TODO_COMMENT]
            .compactMap { [index = derivationIndex] cryptoAccounts in
                return Self._cryptoAccount(forDerivationIndex: index, from: cryptoAccounts)
            }
            .eraseToAnyPublisher()
    }

    var cryptoAccount: StoredCryptoAccount {
        let cryptoAccounts = innerRepository.persistentStorage.getList()

        // [REDACTED_TODO_COMMENT]
        return Self._cryptoAccount(forDerivationIndex: derivationIndex, from: cryptoAccounts) ?? cryptoAccounts[0].withTokens([])
    }

    func performBatchUpdates(_ batchUpdates: BatchUpdates) rethrows {
        let updater = UserTokensRepositoryBatchUpdater()
        try batchUpdates(updater)
        let updates = updater.updates

        for update in updates {
            switch update {
            case .append(let tokenItems):
                let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
                let (updatedAccount, isDirty) = merger.merge(newTokenItems: tokenItems, to: cryptoAccount)

                guard isDirty else {
                    continue
                }

                innerRepository.persistentStorage.appendNewOrUpdateExisting(updatedAccount)
            case .remove(let tokenItem):
                let updatedTokens = cryptoAccount.tokens.filter { $0 != tokenItem.toStoredToken() }
                let updatedAccount = cryptoAccount.withTokens(updatedTokens)
                innerRepository.persistentStorage.appendNewOrUpdateExisting(updatedAccount)
            case .update:
                break // [REDACTED_TODO_COMMENT]
            }
        }

        if updates.isNotEmpty {
            // No account properties were changed here therefore only tokens need to be updated on the server
            innerRepository.updateAccountsOnServer(updateType: .tokens)
        }
    }

    func updateLocalRepositoryFromServer(_ completion: @escaping Completion) {
        // Debounced loading to avoid multiple simultaneous requests when multiple accounts request an update in a short time frame
        innerRepository.debouncer.debounce(withCompletion: completion)
    }

    private static func cryptoAccount(
        forDerivationIndex derivationIndex: Int,
        from cryptoAccounts: [StoredCryptoAccount],
        file: StaticString = #file,
        line: UInt = #line
    ) -> StoredCryptoAccount {
        guard let cryptoAccount = cryptoAccounts.first(where: { $0.derivationIndex == derivationIndex }) else {
            preconditionFailure("No crypto account found for derivation index \(derivationIndex)", file: file, line: line)
        }

        return cryptoAccount
    }

    @available(*, deprecated, message: "Temporary workaround until [REDACTED_INFO] is resolved")
    private static func _cryptoAccount(
        forDerivationIndex derivationIndex: Int,
        from cryptoAccounts: [StoredCryptoAccount],
    ) -> StoredCryptoAccount? {
        return cryptoAccounts.first(where: { $0.derivationIndex == derivationIndex })
    }
}

// MARK: - Auxiliary types

private extension CommonCryptoAccountsRepository {
    actor PendingStateHolder {
        var cryptoAccountsToUpdate: [StoredCryptoAccount]?
    }

    struct RemoteUpdateType: OptionSet {
        let rawValue: Int

        static let accounts = Self(rawValue: 1 << 0)
        static let tokens = Self(rawValue: 1 << 1)
        static let all: Self = [.accounts, .tokens]
    }

    enum InternalError: Error {
        /// Unlike `CryptoAccountsNetworkServiceError.noAccountsCreated`, this error indicates that the wallet
        /// has been created using an older version of the app (i.e. w/o accounts support) and exists,
        /// but no accounts have been created for this wallet yet.
        case migrationNeeded
    }
}

// MARK: - Constants

private extension CommonCryptoAccountsRepository {
    enum Constants {
        static let maxRetryCount = 3
        static let loadAccountsDebounceInterval = 0.3
    }
}

// MARK: - Convenience extensions

@MainActor
private func runOnMainIfNotCancelled(_ code: () throws -> Void) rethrows {
    if !Task.isCancelled {
        try code()
    }
}
