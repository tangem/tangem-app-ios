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
    private typealias StorageDidUpdatePublisher = AnyPublisher<[StoredCryptoAccount], Never>

    @available(iOS, deprecated: 100000.0, message: "For migration purposes only. Will be removed later ([REDACTED_INFO])")
    private let tokenItemsRepository: TokenItemsRepository
    private let defaultAccountFactory: DefaultAccountFactory
    private let networkService: CryptoAccountsNetworkService & WalletsNetworkService
    private let auxiliaryDataStorage: CryptoAccountsAuxiliaryDataStorage
    fileprivate let persistentStorage: CryptoAccountsPersistentStorage
    private let storageController: CryptoAccountsPersistentStorageController
    private let storageDidUpdateSubject: CryptoAccountsPersistentStorageController.StorageDidUpdateSubject
    private let stateHolder: StateHolder

    /// Implicitly unwrapped to resolve circular dependency
    fileprivate var loadAccountsFromServerDebouncer: Debouncer<UserTokensRepository.Result>! // [REDACTED_TODO_COMMENT]

    /// Implicitly unwrapped to resolve circular dependency
    fileprivate var updateTokensOnServerDebouncer: Debouncer<UserTokensRepository.Result>! // [REDACTED_TODO_COMMENT]

    private weak var userWalletInfoProvider: UserWalletInfoProvider?

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

    private let hasTokenSynchronization: Bool

    private var loadAccountsSubscription: AnyCancellable?
    private var saveAccountsSubscription: AnyCancellable?
    private var storageDidUpdateSubscription: AnyCancellable?

    init(
        tokenItemsRepository: TokenItemsRepository,
        defaultAccountFactory: DefaultAccountFactory,
        networkService: CryptoAccountsNetworkService & WalletsNetworkService,
        auxiliaryDataStorage: CryptoAccountsAuxiliaryDataStorage,
        persistentStorage: CryptoAccountsPersistentStorage,
        storageController: CryptoAccountsPersistentStorageController,
        hasTokenSynchronization: Bool
    ) {
        storageDidUpdateSubject = .init()
        stateHolder = .init()
        self.tokenItemsRepository = tokenItemsRepository
        self.defaultAccountFactory = defaultAccountFactory
        self.networkService = networkService
        self.auxiliaryDataStorage = auxiliaryDataStorage
        self.persistentStorage = persistentStorage
        self.storageController = storageController
        self.hasTokenSynchronization = hasTokenSynchronization

        loadAccountsFromServerDebouncer = Debouncer(interval: Constants.debounceInterval) { [weak self] completion in
            self?.loadAccountsFromServer(completion)
        }

        updateTokensOnServerDebouncer = Debouncer(interval: Constants.debounceInterval) { [weak self] completion in
            // No account properties were changed here therefore only tokens need to be updated on the server
            self?.updateAccountsOnServer(updateOptions: .tokens, completion: completion)
        }

        storageController.bind(to: storageDidUpdateSubject)
    }

    // MARK: - Configuration

    func configure(with userWalletInfoProvider: UserWalletInfoProvider) {
        self.userWalletInfoProvider = userWalletInfoProvider
    }

    // MARK: - Legacy storage migration and initialization, not accounts created, no wallets created, etc.

    private func initializeStorage(with initialAccount: StoredCryptoAccount) {
        persistentStorage.replace(with: [initialAccount])
        auxiliaryDataStorage.update(withArchivedAccountsCount: 0, totalAccountsCount: 1)
    }

    private func migrateStorage(forUserWalletWithId userWalletId: UserWalletId) {
        let mainAccountPersistentConfig = AccountModelUtils.mainAccountPersistentConfig(forUserWalletWithId: userWalletId)
        let legacyStoredTokenList = tokenItemsRepository.getList()
        let tokens = LegacyStoredEntryConverter.convert(legacyStoredTokens: legacyStoredTokenList.entries)
        let tokenListAppearance = LegacyStoredEntryConverter.convert(legacyStoredTokenListToAppearance: legacyStoredTokenList)
        let newCryptoAccount = StoredCryptoAccount(
            config: mainAccountPersistentConfig,
            tokenListAppearance: tokenListAppearance,
            tokens: tokens
        )
        initializeStorage(with: newCryptoAccount)
    }

    private func createWallet() async throws {
        guard let userWalletInfo = userWalletInfoProvider?.userWalletInfo else {
            throw InternalError.noUserWalletInfoProviderSet
        }

        let walletCreationHelper = WalletCreationHelper(
            userWalletInfo: userWalletInfo,
            networkService: networkService
        )

        try await walletCreationHelper.createWallet()
    }

    private func addDefaultAccount(isWalletAlreadyCreated: Bool, additionalTokens: [StoredCryptoAccount.Token]) async throws {
        if !isWalletAlreadyCreated {
            try await createWallet()
        }

        // In some rare edge cases, when a wallet has already been created and used on a previous app version
        // (w/o accounts support) and this wallet has an empty token list, default tokens from
        // `DefaultAccountFactory.defaultBlockchains` (i.e. `UserWalletConfig.defaultBlockchains`) will be added
        // to the newly created account. We consider this behavior acceptable (mirrors the Android implementation).
        let defaultAccount = defaultAccountFactory.makeDefaultAccount(defaultTokensOverride: additionalTokens)
        _ = try await addAccountsInternal([defaultAccount], tokenListUpdateOptions: .forceUpdate)
    }

    // MARK: - Loading accounts and tokens from server

    private func loadAccountsFromServer(_ completion: UserTokensRepository.Completion? = nil) {
        guard hasTokenSynchronization else {
            completion?(.success(()))
            return
        }

        loadAccountsSubscription = runTask(in: self) { repository in
            let hasScheduledPendingUpdate = await repository.stateHolder.performIsolated { holder in
                guard
                    let pending = holder.cryptoAccountsToUpdate,
                    !Task.isCancelled
                else {
                    return false
                }

                holder.cryptoAccountsToUpdate = nil
                repository.updateAccountsOnServer(cryptoAccounts: pending, updateOptions: .all, completion: completion)

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
                await runOnMainIfNotCancelled { completion?(.success(())) }
            } catch {
                await repository.handleFailedLoadingAccountsFromServer(error: error, completion: completion)
            }
        }.eraseToAnyCancellable()
    }

    private func loadAccountsFromServerAsync() async throws {
        do {
            let remoteCryptoAccountsInfo = try await networkService.getCryptoAccounts(retryCount: 0)
            try Task.checkCancellation()

            var updatedAccounts = remoteCryptoAccountsInfo.accounts
            if updatedAccounts.isEmpty {
                throw InternalError.migrationNeeded(additionalTokens: remoteCryptoAccountsInfo.legacyTokens)
            }

            let shouldUpdateTokenListDueToTokensDistribution = StoredCryptoAccountsTokensDistributor.distributeTokens(
                in: &updatedAccounts,
                additionalTokens: remoteCryptoAccountsInfo.legacyTokens
            ).isRedistributionHappened

            let shouldUpdateTokenListDueToCustomTokensMigration = await tryMigrateCustomTokensOnce(in: &updatedAccounts)

            // Updating the local storage first since it's the primary purpose of this method
            persistentStorage.replace(with: updatedAccounts)
            auxiliaryDataStorage.update(withRemoteInfo: remoteCryptoAccountsInfo)

            if shouldUpdateTokenListDueToTokensDistribution || shouldUpdateTokenListDueToCustomTokensMigration {
                // Tokens distribution between different accounts and/or custom tokens migration were performed,
                // therefore tokens need to be updated on the server
                try await updateAccountsOnServerAsync(cryptoAccounts: updatedAccounts, updateOptions: .tokens)
            }
        } catch CryptoAccountsNetworkServiceError.missingRevision, CryptoAccountsNetworkServiceError.inconsistentState {
            // Impossible case, since we don't update remote accounts here
            preconditionFailure("Unexpected state: missing revision or inconsistent state when loading accounts from server")
        } catch CryptoAccountsNetworkServiceError.underlyingError(let error) {
            throw error
        } catch CryptoAccountsNetworkServiceError.noAccountsCreated {
            try await addDefaultAccount(isWalletAlreadyCreated: false, additionalTokens: [])
        } catch InternalError.migrationNeeded(let additionalTokens) {
            try await addDefaultAccount(isWalletAlreadyCreated: true, additionalTokens: additionalTokens)
        }
    }

    private func handleFailedLoadingAccountsFromServer(error: Error, completion: UserTokensRepository.Completion?) async {
        guard !error.isCancellationError else {
            return
        }

        await runOnMainIfNotCancelled { completion?(.failure(error)) }
    }

    // MARK: - Updating accounts and tokens on server

    private func updateAccountsOnServer(
        cryptoAccounts: [StoredCryptoAccount]? = nil,
        updateOptions: RemoteUpdateOptions,
        completion: UserTokensRepository.Completion? = nil
    ) {
        guard hasTokenSynchronization else {
            completion?(.success(()))
            return
        }

        saveAccountsSubscription = runTask(in: self) { repository in
            let cryptoAccounts = cryptoAccounts ?? repository.persistentStorage.getList()

            do {
                try await repository.updateAccountsOnServerAsync(cryptoAccounts: cryptoAccounts, updateOptions: updateOptions)
                await runOnMainIfNotCancelled { completion?(.success(())) }
            } catch {
                await repository.handleFailedUpdateAccountsOnServer(cryptoAccounts: cryptoAccounts, error: error, completion: completion)
            }
        }.eraseToAnyCancellable()
    }

    private func updateAccountsOnServerAsync(cryptoAccounts: [StoredCryptoAccount], updateOptions: RemoteUpdateOptions) async throws {
        do {
            if updateOptions.contains(.accounts) {
                try await networkService.saveAccounts(from: cryptoAccounts, retryCount: 0)
            }
            if updateOptions.contains(.tokens) {
                try await networkService.saveTokens(from: cryptoAccounts, tokenListUpdateOptions: .none)
            }
        } catch CryptoAccountsNetworkServiceError.missingRevision, CryptoAccountsNetworkServiceError.inconsistentState {
            try await refreshInconsistentState()
            try Task.checkCancellation()
            try await updateAccountsOnServerAsync(cryptoAccounts: cryptoAccounts, updateOptions: updateOptions) // Schedules a retry after fixing the state
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

        await stateHolder.performIsolated { holder in
            guard !Task.isCancelled else {
                return
            }

            holder.cryptoAccountsToUpdate = cryptoAccounts
        }

        await runOnMainIfNotCancelled { completion?(.failure(error)) }
    }

    private func refreshInconsistentState() async throws {
        // Implicitly refreshes the revision (i.e. the `ETag` header)
        try await networkService.getCryptoAccounts(retryCount: Constants.maxRetryCount)
    }

    // MARK: - Internal CRUD methods for accounts (always remote first, then local)

    private func addNewOrUpdateExistingAccountInternal(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState,
    ) async throws -> StoredCryptoAccountsTokensDistributor.DistributionResult {
        let tokenListAppearance = cryptoAccountTokenListAppearance(withConfig: config, remoteState: remoteState)
        let newCryptoAccount = StoredCryptoAccount(config: config, tokenListAppearance: tokenListAppearance)
        let existingCryptoAccounts = remoteState.accounts
        let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: true)
        let (editedItems, isDirty) = merger.merge(oldAccounts: existingCryptoAccounts, newAccounts: [newCryptoAccount])

        if isDirty {
            // This methods either adds a new account w/o tokens or updates an existing one, preserving its tokens
            // Therefore there is no need to forcefully update the token list
            //
            // Also, in case of a failure when updating the token list while adding/updating an account, the attempt to
            // update the token list will be performed on every following synchronization, so errors can be ignored here
            return try await addAccountsInternal(editedItems, tokenListUpdateOptions: [.ignoreErrors])
        }

        // No changes were made, no tokens redistribution performed
        return .none
    }

    private func addAccountsInternal(
        _ accounts: [StoredCryptoAccount],
        tokenListUpdateOptions: TokenListUpdateOptions
    ) async throws -> StoredCryptoAccountsTokensDistributor.DistributionResult {
        let remoteCryptoAccountsInfo = try await networkService.saveAccounts(from: accounts, retryCount: 0)
        try Task.checkCancellation()

        var updatedAccounts: [StoredCryptoAccount]
        let distributionResult: StoredCryptoAccountsTokensDistributor.DistributionResult

        if tokenListUpdateOptions.contains(.forceUpdate) {
            try await networkService.saveTokens(from: accounts, tokenListUpdateOptions: tokenListUpdateOptions)
            try Task.checkCancellation()
            // Overriding the remote state when the token list is forcefully updated
            // to ensure that tokens from the newly added accounts are always saved
            updatedAccounts = accounts
            // Force update doesn't need tokens redistribution by definition
            distributionResult = .none
        } else {
            updatedAccounts = remoteCryptoAccountsInfo.accounts

            distributionResult = StoredCryptoAccountsTokensDistributor.distributeTokens(
                in: &updatedAccounts,
                additionalTokens: remoteCryptoAccountsInfo.legacyTokens
            )

            if distributionResult.isRedistributionHappened {
                try await networkService.saveTokens(from: updatedAccounts, tokenListUpdateOptions: tokenListUpdateOptions)
                try Task.checkCancellation()
            }
        }

        // Updating local storage only after successful remote update
        persistentStorage.replace(with: updatedAccounts)
        auxiliaryDataStorage.update(withRemoteInfo: remoteCryptoAccountsInfo)

        return distributionResult
    }

    /// - Note: Unlike adding or updating accounts (using `addAccountsInternal` method),
    /// removing accounts doesn't require token distribution after updating the remote state.
    private func removeAccountsInternal(_ identifier: some Hashable) async throws {
        var existingCryptoAccounts = persistentStorage.getList()
        existingCryptoAccounts.removeAll { $0.derivationIndex.toAnyHashable() == identifier.toAnyHashable() }

        let remoteCryptoAccountsInfo = try await networkService.saveAccounts(from: existingCryptoAccounts, retryCount: 0)
        try Task.checkCancellation()

        // Updating local storage only after successful remote update
        persistentStorage.removeAll { $0.derivationIndex.toAnyHashable() == identifier.toAnyHashable() }
        auxiliaryDataStorage.update(withRemoteInfo: remoteCryptoAccountsInfo)
    }

    private func cryptoAccountTokenListAppearance(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState,
    ) -> CryptoAccountPersistentConfig.TokenListAppearance {
        // Currently, the token list appearance is shared between all accounts within a unique wallet and therefore
        // has the same value for all accounts. So, we can simply take the appearance from any existing remote account
        // if there is no account matching the provided derivation index.
        let accounts = remoteState.accounts
        let account = accounts.first { $0.derivationIndex == config.derivationIndex } ?? accounts.first

        // Pretty much dead code path, since there always exists at least one account
        guard let account else {
            return .default
        }

        return CryptoAccountPersistentConfig.TokenListAppearance(grouping: account.grouping, sorting: account.sorting)
    }

    // MARK: - Custom tokens upgrade and migration

    /// `Once` means that migration will be attempted only once per life cycle of the repository instance.
    private func tryMigrateCustomTokensOnce(in storedCryptoAccounts: inout [StoredCryptoAccount]) async -> Bool {
        guard await !stateHolder.areCustomTokensMigrated else {
            return false
        }

        await stateHolder.performIsolated { $0.areCustomTokensMigrated = true }

        let migrator = StoredCryptoAccountsCustomTokensMigrator()
        return await migrator.migrateTokensIfNeeded(in: &storedCryptoAccounts)
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
        guard storageController.isMigrationNeeded() else {
            return
        }

        if tokenItemsRepository.containsFile {
            // There is no need to call `loadAccountsFromServer` explicitly here, as this migration will create the main
            // account, and its user tokens manager will trigger the initial synchronization with the remote server
            migrateStorage(forUserWalletWithId: userWalletId)
        } else if !hasTokenSynchronization {
            // Local-only storage initialization with a default account
            initializeStorage(with: defaultAccountFactory.makeDefaultAccount(defaultTokensOverride: []))
        } else {
            // Last resort option: initialize storage with remote info from the server
            loadAccountsFromServer()
        }
    }

    func getRemoteState() async throws -> CryptoAccountsRemoteState {
        let cryptoAccounts = try await networkService.getCryptoAccounts(retryCount: 0)
        try Task.checkCancellation()

        return CryptoAccountsRemoteState(
            nextDerivationIndex: cryptoAccounts.counters.total,
            accounts: cryptoAccounts.accounts
        )
    }

    func addNewCryptoAccount(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState
    ) async throws -> StoredCryptoAccountsTokensDistributor.DistributionResult {
        return try await addNewOrUpdateExistingAccountInternal(withConfig: config, remoteState: remoteState)
    }

    func updateExistingCryptoAccount(
        withConfig config: CryptoAccountPersistentConfig,
        remoteState: CryptoAccountsRemoteState
    ) async throws {
        // Ignoring the result, as tokens redistribution can't be performed when editing an existing account
        let _ = try await addNewOrUpdateExistingAccountInternal(withConfig: config, remoteState: remoteState)
    }

    func removeCryptoAccount(withIdentifier identifier: some Hashable) async throws {
        try await removeAccountsInternal(identifier)
    }

    func reorderCryptoAccounts(orderedIdentifiers: [some Hashable]) async throws {
        let orderedIndicesKeyedByIdentifiers = orderedIdentifiers
            .enumerated()
            .reduce(into: [:]) { partialResult, element in
                partialResult[element.element.toAnyHashable()] = element.offset
            }

        let orderedCryptoAccounts = persistentStorage
            .getList()
            .sorted { first, second in
                guard
                    let firstIndex = orderedIndicesKeyedByIdentifiers[first.derivationIndex.toAnyHashable()],
                    let secondIndex = orderedIndicesKeyedByIdentifiers[second.derivationIndex.toAnyHashable()]
                else {
                    // Preserve existing order
                    return false
                }

                return firstIndex < secondIndex
            }

        persistentStorage.replace(with: orderedCryptoAccounts)

        return try await updateAccountsOnServerAsync(cryptoAccounts: orderedCryptoAccounts, updateOptions: .accounts)
    }
}

// MARK: - UserTokensPushNotificationsRemoteStatusSyncing protocol conformance

extension CommonCryptoAccountsRepository: UserTokensPushNotificationsRemoteStatusSyncing {
    func syncRemoteStatus() {
        updateAccountsOnServer(updateOptions: .tokens)
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
        let index = derivationIndex

        return innerRepository
            .cryptoAccountsPublisher
            // Removal of the account triggers `innerRepository.cryptoAccountsPublisher` to emit a new value,
            // but in this case the account is already removed so we have to skip this value
            .filter { $0.contains { $0.derivationIndex == index } }
            .map { Self.cryptoAccount(forDerivationIndex: index, from: $0) }
            .eraseToAnyPublisher()
    }

    var cryptoAccount: StoredCryptoAccount {
        let cryptoAccounts = innerRepository.persistentStorage.getList()

        return Self.cryptoAccount(forDerivationIndex: derivationIndex, from: cryptoAccounts)
    }

    func performBatchUpdates(_ batchUpdates: BatchUpdates) rethrows {
        let updater = UserTokensRepositoryBatchUpdater()
        try batchUpdates(updater)
        let updates = updater.updates

        for update in updates {
            let updatedAccount: StoredCryptoAccount

            switch update {
            case .append(let tokenItems):
                let merger = StoredCryptoAccountsMerger(preserveTokensWhileMergingAccounts: false)
                let (account, isDirty) = merger.merge(newTokenItems: tokenItems, to: cryptoAccount)

                guard isDirty else {
                    continue
                }

                updatedAccount = account
            case .remove(let tokenItem):
                let updatedTokens = cryptoAccount
                    .tokens
                    .filter { $0 != tokenItem.toStoredToken() }
                updatedAccount = cryptoAccount.withTokens(updatedTokens)
            case .update(let request):
                updatedAccount = cryptoAccount
                    .with(sorting: request.sorting, grouping: request.grouping)
                    .withTokens(request.tokens)
            }

            innerRepository.persistentStorage.appendNewOrUpdateExisting(updatedAccount)
        }

        if updates.isNotEmpty {
            innerRepository.updateTokensOnServerDebouncer.debounce(withCompletion: { _ in })
        }
    }

    func updateLocalRepositoryFromServer(_ completion: @escaping Completion) {
        // Debounced loading to avoid multiple simultaneous requests when multiple accounts request an update in a short time frame
        innerRepository.loadAccountsFromServerDebouncer.debounce(withCompletion: completion)
    }

    private static func cryptoAccount(
        forDerivationIndex derivationIndex: Int,
        from cryptoAccounts: [StoredCryptoAccount],
        file: StaticString = #file,
        line: UInt = #line
    ) -> StoredCryptoAccount {
        guard let cryptoAccount = cryptoAccounts.first(where: { $0.derivationIndex == derivationIndex }) else {
            #if ALPHA || BETA || DEBUG
            preconditionFailure(
                "No crypto account found for derivation index '\(derivationIndex)' in crypto accounts: '\(cryptoAccounts)'",
                file: file,
                line: line
            )
            #else
            return .dummy(withDerivationIndex: derivationIndex)
            #endif // ALPHA || BETA || DEBUG
        }

        return cryptoAccount
    }
}

// MARK: - Auxiliary types

private extension CommonCryptoAccountsRepository {
    /// Provides synchronized access to mutable state of the repository.
    actor StateHolder {
        /// Bool flag for migration of custom tokens to tokens form our API.
        var areCustomTokensMigrated = false
        var cryptoAccountsToUpdate: [StoredCryptoAccount]?
    }

    struct RemoteUpdateOptions: OptionSet {
        let rawValue: Int

        static let accounts = Self(rawValue: 1 << 0)
        static let tokens = Self(rawValue: 1 << 1)
        static let all: Self = [.accounts, .tokens]
    }

    struct TokenListUpdateOptions: OptionSet {
        let rawValue: Int

        /// Forcefully updates the token list on the server, even if no changes were detected locally.
        static let forceUpdate = Self(rawValue: 1 << 0)
        /// Ignores errors that occur during token list update on the server.
        static let ignoreErrors = Self(rawValue: 1 << 1)
        static let none: Self = []
    }

    enum InternalError: Error {
        /// Unlike `CryptoAccountsNetworkServiceError.noAccountsCreated`, this error indicates that the wallet
        /// has been created using an older version of the app (i.e. w/o accounts support) and exists,
        /// but no accounts have been created for this wallet yet.
        case migrationNeeded(additionalTokens: [StoredCryptoAccount.Token])
        /// No `UserWalletInfoProvider` has been configured for the repository, this is most likely a programming error.
        /// Check that `configure(with:)` method has been called before using the repository.
        case noUserWalletInfoProviderSet
    }
}

// MARK: - Constants

private extension CommonCryptoAccountsRepository {
    enum Constants {
        static let maxRetryCount = 3
        static let debounceInterval = 0.3
    }
}

// MARK: - Convenience extensions

@MainActor
private func runOnMainIfNotCancelled(_ code: () throws -> Void) rethrows {
    if !Task.isCancelled {
        try code()
    }
}

private extension CryptoAccountsNetworkService {
    /// Convenience helper to save tokens with given options and a predefined retry count.
    func saveTokens(
        from accounts: [StoredCryptoAccount],
        tokenListUpdateOptions: CommonCryptoAccountsRepository.TokenListUpdateOptions
    ) async throws {
        do {
            try await saveTokens(from: accounts, retryCount: CommonCryptoAccountsRepository.Constants.maxRetryCount)
        } catch {
            if !tokenListUpdateOptions.contains(.ignoreErrors) {
                throw error
            }
        }
    }
}
