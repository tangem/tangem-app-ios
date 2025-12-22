//
//  CommonAccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

actor CommonAccountModelsManager {
    private typealias AccountId = CommonCryptoAccountModel.AccountId
    private typealias Cache = [AccountId: CommonCryptoAccountModel]

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    private nonisolated let cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider
    private nonisolated let cryptoAccountsRepository: CryptoAccountsRepository
    private let archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider
    private let dependenciesFactory: CryptoAccountDependenciesFactory

    private let executor: any SerialExecutor
    private let userWalletId: UserWalletId
    private let areHDWalletsSupported: Bool

    /// - Note: Manual synchronization is used for reads/writes, hence it is safe to mark this as `nonisolated(unsafe)`.
    private nonisolated(unsafe) var unsafeAccountModelsPublisher: AnyPublisher<[AccountModel], Never>?
    private nonisolated(unsafe) var unsafeAccountModels: [AccountModel] = []
    private nonisolated let criticalSection: Lock

    init(
        userWalletId: UserWalletId,
        cryptoAccountsRepository: CryptoAccountsRepository,
        archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider,
        dependenciesFactory: CryptoAccountDependenciesFactory,
        areHDWalletsSupported: Bool
    ) {
        self.userWalletId = userWalletId
        self.cryptoAccountsRepository = cryptoAccountsRepository
        self.archivedCryptoAccountsProvider = archivedCryptoAccountsProvider
        self.dependenciesFactory = dependenciesFactory
        self.areHDWalletsSupported = areHDWalletsSupported
        executor = Executor(label: userWalletId.stringValue)
        criticalSection = Lock(isRecursive: false)

        // Synchronization for `cryptoAccountsGlobalStateProvider` is guaranteed by the initialization of Swift static variables,
        // so it is safe to mark `cryptoAccountsGlobalStateProvider` as `nonisolated`.
        // Unfortunately, property wrappers cannot be marked as `nonisolated`, so we need to manually inject the dependency.
        @Injected(\.cryptoAccountsGlobalStateProvider)
        var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider
        self.cryptoAccountsGlobalStateProvider = cryptoAccountsGlobalStateProvider
        cryptoAccountsGlobalStateProvider.register(self, forIdentifier: userWalletId)

        initialize()
    }

    deinit {
        // [REDACTED_TODO_COMMENT]
        cryptoAccountsGlobalStateProvider.unregister(self, forIdentifier: userWalletId)
    }

    private nonisolated func initialize() {
        runTask(in: self, isDetached: true) { manager in
            await manager.cryptoAccountsRepository.initialize(forUserWalletWithId: manager.userWalletId)
        }
    }

    private func makeCryptoAccountModels(
        from storedCryptoAccounts: [StoredCryptoAccount],
        cache: inout Cache
    ) -> [any CryptoAccountModel] {
        // [REDACTED_TODO_COMMENT]
        let currentAccountIds = cache.keys.toSet()
        var storedCryptoAccountsKeyedByAccountIds: [AccountId: StoredCryptoAccount] = [:]

        let newAccountIds = storedCryptoAccounts
            .compactMap { storedCryptoAccount in
                let accountId = AccountId(userWalletId: userWalletId, derivationIndex: storedCryptoAccount.derivationIndex)

                // Updating the `storedCryptoAccountsKeyedByAccountIds` dict within this `compactMap` loop to reduce the number of iterations
                storedCryptoAccountsKeyedByAccountIds[accountId] = storedCryptoAccount

                return accountId
            }

        let removedAccountIds = currentAccountIds.subtracting(newAccountIds)
        cache.removeAll { removedAccountIds.contains($0.key) }
        let cachedAccountsIds = cache.keys.toSet() // Snapshot of currently cached account IDs before adding new ones

        let newCryptoAccounts = newAccountIds
            .compactMap { accountId -> CommonCryptoAccountModel? in
                guard let storedCryptoAccount = storedCryptoAccountsKeyedByAccountIds[accountId] else {
                    let message = "Stored crypto account not found for accountId: \(accountId)"
                    AccountsLogger.warning(message)
                    assertionFailure(message)
                    return nil
                }

                guard let accountIcon = AccountModel.Icon(
                    rawName: storedCryptoAccount.icon.iconName,
                    rawColor: storedCryptoAccount.icon.iconColor
                ) else {
                    let message = "Invalid icon for stored crypto account: \(storedCryptoAccount)"
                    AccountsLogger.warning(message)
                    assertionFailure(message)
                    return nil
                }

                // Early exit if the account is already created and cached
                if let cachedAccount = cache[accountId] {
                    // Update cached account properties in case they were changed remotely
                    return cachedAccount.update { editor in
                        storedCryptoAccount.name.map(editor.setName)
                        editor.setIcon(accountIcon)
                    }
                }

                let derivationIndex = storedCryptoAccount.derivationIndex
                let dependencies = dependenciesFactory.makeDependencies(
                    forAccountWithDerivationIndex: derivationIndex,
                    userWalletId: userWalletId
                )
                let balanceProvidingDependencies = dependencies.makeBalanceProvidingDependencies()

                let cryptoAccount = CommonCryptoAccountModel(
                    userWalletId: userWalletId,
                    accountName: storedCryptoAccount.name,
                    accountIcon: accountIcon,
                    derivationIndex: derivationIndex,
                    walletModelsManager: dependencies.walletModelsManager,
                    userTokensManager: dependencies.userTokensManager,
                    accountBalanceProvider: balanceProvidingDependencies.balanceProvider,
                    accountRateProvider: balanceProvidingDependencies.ratesProvider,
                    derivationManager: dependencies.derivationManager,
                    delegate: self
                )

                dependencies.walletModelsFactoryInput.setCryptoAccount(cryptoAccount)
                // Uses `walletModelsFactory` internally, therefore must be initialized after setting the account in `walletModelsFactoryInput`
                dependencies.walletModelsManager.initialize()
                // Updating `cache` within this `compactMap` loop to reduce the number of iterations
                cache[accountId] = cryptoAccount

                return cryptoAccount
            }

        // Trigger initial synchronization for all newly created accounts. Creating `newCryptoAccounts` is performed
        // on a serial executor, so it may take some time if many accounts need to be created.
        for newCryptoAccount in newCryptoAccounts where !cachedAccountsIds.contains(newCryptoAccount.id) {
            newCryptoAccount.userTokensManager.sync {}
        }

        return newCryptoAccounts
    }

    /// - Note: Manual synchronization is used since this publisher must be created in a lazy manner and lazy properties not really
    /// supported in actors (compiler warning on Swift 5.x and compiler error on Swift 6; see https://forums.swift.org/t/74609 for details).
    private nonisolated func makeOrGetAccountModelsPublisher() -> AnyPublisher<[AccountModel], Never> {
        return criticalSection {
            if let publisher = unsafeAccountModelsPublisher {
                return publisher
            }

            var cache: Cache = [:]
            let publisher = cryptoAccountsRepository
                .cryptoAccountsPublisher
                .combineLatest(cryptoAccountsGlobalStateProvider.globalCryptoAccountsStatePublisher())
                .withWeakCaptureOf(self)
                .asyncMap { manager, input -> [AccountModel] in
                    let (storedCryptoAccounts, globalState) = input
                    let cryptoAccountModels = await manager.makeCryptoAccountModels(from: storedCryptoAccounts, cache: &cache)
                    let cryptoAccountsBuilder = CryptoAccountsBuilder(globalState: globalState)
                    let cryptoAccounts = cryptoAccountsBuilder.build(from: cryptoAccountModels)

                    return [
                        .standard(cryptoAccounts),
                    ]
                }
                .handleEvents(receiveOutput: { [weak self] accountModels in
                    self?.criticalSection {
                        self?.unsafeAccountModels = accountModels
                    }
                })
                .eraseToAnyPublisher()

            unsafeAccountModelsPublisher = publisher

            return publisher
        }
    }

    private func makeConditionsValidator(for flow: ValidationFlow) -> any CryptoAccountConditionsValidator {
        switch flow {
        case .new(let newAccountName, let remoteState):
            return NewCryptoAccountConditionsValidator(newAccountName: newAccountName, remoteState: remoteState)
        case .edit(let newAccountName, let derivationIndex, let remoteState):
            return EditCryptoAccountConditionsValidator(
                newAccountName: newAccountName,
                derivationIndex: derivationIndex,
                remoteState: remoteState
            )
        case .archive(let identifier):
            let accountModelPublisher = accountModelsPublisher
                .compactMap { $0.cryptoAccount(with: identifier) }
                .eraseToAnyPublisher()

            return ArchivedCryptoAccountConditionsValidator(
                userWalletId: userWalletId,
                accountIdentifier: identifier,
                accountModelPublisher: accountModelPublisher
            )
        case .unarchive(let info, let remoteState):
            return UnarchivedCryptoAccountConditionsValidator(
                newAccountName: info.name,
                identifier: info.id,
                remoteState: remoteState
            )
        }
    }

    private func editCryptoAccountModel(with config: CryptoAccountPersistentConfig) async throws(AccountEditError) {
        let remoteState: CryptoAccountsRemoteState

        do {
            remoteState = try await cryptoAccountsRepository.getRemoteState()
        } catch {
            AccountsLogger.error("Failed to fetch remote state for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }

        let validator = makeConditionsValidator(
            for: .edit(newAccountName: config.name, derivationIndex: config.derivationIndex, remoteState: remoteState)
        )

        do {
            try await validator.validate()
        } catch let error as AccountEditError {
            AccountsLogger.error("An edited account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
            throw error
        } catch {
            AccountsLogger.error("An edited account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
            throw .unknownError(error)
        }

        do {
            try await cryptoAccountsRepository.updateExistingCryptoAccount(withConfig: config, remoteState: remoteState)
        } catch {
            AccountsLogger.error("Failed to edit crypto account for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }
    }

    private func archiveCryptoAccount(withIdentifier identifier: any AccountModelPersistentIdentifierConvertible) async throws(AccountArchivationError) {
        let validator = makeConditionsValidator(for: .archive(identifier: identifier))

        do {
            try await validator.validate()
        } catch let error as AccountArchivationError {
            AccountsLogger.error("A attempt to archive account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
            throw error
        } catch {
            AccountsLogger.error("A attempt to archive account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
            throw .unknownError(error)
        }

        do {
            try await cryptoAccountsRepository.removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier())
        } catch {
            AccountsLogger.error("Failed to archive existing crypto account with id \(identifier) for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }
    }

    private func mapDistributionResult(
        _ distributionResult: StoredCryptoAccountsTokensDistributor.DistributionResult
    ) -> AccountOperationResult {
        switch distributionResult {
        case .none:
            return .none
        case .redistributionHappened(let pairs):
            return .redistributionHappened(pairs: pairs)
        }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension CommonAccountModelsManager: AccountModelsManager {
    nonisolated var canAddCryptoAccounts: Bool {
        areHDWalletsSupported
    }

    nonisolated var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> {
        cryptoAccountsRepository
            .auxiliaryDataPublisher
            .map { $0.archivedAccountsCount > 0 }
            .eraseToAnyPublisher()
    }

    nonisolated var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        cryptoAccountsRepository
            .auxiliaryDataPublisher
            .map(\.totalAccountsCount)
            .eraseToAnyPublisher()
    }

    nonisolated var accountModels: [AccountModel] {
        criticalSection {
            unsafeAccountModels
        }
    }

    nonisolated var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        makeOrGetAccountModelsPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountEditError) -> AccountOperationResult {
        guard canAddCryptoAccounts else {
            throw .unknownError(AccountModelsManagerError.addingCryptoAccountsNotSupported)
        }

        let remoteState: CryptoAccountsRemoteState

        do {
            remoteState = try await cryptoAccountsRepository.getRemoteState()
        } catch {
            AccountsLogger.error("Failed to fetch remote state for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }

        let validator = makeConditionsValidator(for: .new(newAccountName: name, remoteState: remoteState))

        do {
            try await validator.validate()
        } catch let error as AccountEditError {
            AccountsLogger.error("A new account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
            throw error
        } catch {
            AccountsLogger.error("A new account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
            throw .unknownError(error)
        }

        let newAccountConfig = CryptoAccountPersistentConfig(
            derivationIndex: remoteState.nextDerivationIndex,
            name: name,
            icon: icon
        )

        do {
            let distributionResult = try await cryptoAccountsRepository.addNewCryptoAccount(withConfig: newAccountConfig, remoteState: remoteState)
            return mapDistributionResult(distributionResult)
        } catch {
            AccountsLogger.error("Failed to add new crypto account for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        do {
            return try await archivedCryptoAccountsProvider.getArchivedCryptoAccounts()
        } catch {
            AccountsLogger.error("Failed to fetch archived crypto accounts for user wallet \(userWalletId)", error: error)
            throw .cannotFetchArchivedCryptoAccounts
        }
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult {
        var info = info
        let remoteState: CryptoAccountsRemoteState

        do {
            remoteState = try await cryptoAccountsRepository.getRemoteState()
        } catch {
            AccountsLogger.error("Failed to fetch remote state for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }

        // Validation is performed in a loop to handle the case when the account name remains duplicated
        // even after appending a suffix after first N iterations.
        // Consider the scenario when there are two existing accounts named 'my account' and 'my account(1)'
        // and an archived account named 'my account'.
        while true {
            let validator = makeConditionsValidator(for: .unarchive(info: info, remoteState: remoteState))
            do {
                try await validator.validate()
                break
            } catch AccountRecoveryError.duplicateAccountName {
                let newName = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: info.name)
                info = info.withName(newName)
            } catch let error as AccountRecoveryError {
                AccountsLogger.error("A attempt to unarchive account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
                throw error
            } catch {
                AccountsLogger.error("A attempt to unarchive account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
                throw .unknownError(error)
            }
        }

        let persistentConfig = info.toPersistentConfig()

        do {
            let distributionResult = try await cryptoAccountsRepository.addNewCryptoAccount(withConfig: persistentConfig, remoteState: remoteState)
            return mapDistributionResult(distributionResult)
        } catch {
            AccountsLogger.error("Failed to unarchive existing crypto account with id \(info.id) for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }
    }
}

// MARK: - CommonCryptoAccountModelDelegate protocol conformance

extension CommonAccountModelsManager: CommonCryptoAccountModelDelegate {
    func commonCryptoAccountModel(
        _ model: CommonCryptoAccountModel,
        wantsToUpdateWith config: CryptoAccountPersistentConfig
    ) async throws(AccountEditError) {
        try await editCryptoAccountModel(with: config)
    }

    func commonCryptoAccountModelWantsToArchive(_ model: CommonCryptoAccountModel) async throws(AccountArchivationError) {
        try await archiveCryptoAccount(withIdentifier: model.id)
    }
}

// MARK: - AccountModelsReordering protocol conformance

extension CommonAccountModelsManager: AccountModelsReordering {
    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws {
        try await cryptoAccountsRepository.reorderCryptoAccounts(
            orderedIdentifiers: orderedIdentifiers.map { $0.toPersistentIdentifier().toAnyHashable() }
        )
    }
}

// MARK: - Auxiliary types

private extension CommonAccountModelsManager {
    final class Executor: SerialExecutor {
        private let workingQueue: DispatchQueue

        init(label: String) {
            workingQueue = DispatchQueue(
                label: "com.tangem.CommonAccountModelsManager.Executor.workingQueue_\(label)",
                target: .global(qos: .userInitiated)
            )
        }

        func enqueue(_ job: UnownedJob) {
            let executor = asUnownedSerialExecutor()
            workingQueue.async {
                job.runSynchronously(on: executor)
            }
        }

        func asUnownedSerialExecutor() -> UnownedSerialExecutor {
            UnownedSerialExecutor(ordinary: self)
        }
    }

    private enum ValidationFlow {
        case new(newAccountName: String, remoteState: CryptoAccountsRemoteState)
        case edit(newAccountName: String?, derivationIndex: Int, remoteState: CryptoAccountsRemoteState)
        case archive(identifier: any AccountModelPersistentIdentifierConvertible)
        case unarchive(info: ArchivedCryptoAccountInfo, remoteState: CryptoAccountsRemoteState)
    }
}
