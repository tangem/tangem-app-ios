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
import TangemNFT

actor CommonAccountModelsManager {
    private typealias AccountId = CommonCryptoAccountModel.AccountId
    private typealias CacheEntry = (model: CommonCryptoAccountModel, didChangeSubscription: AnyCancellable)
    private typealias Cache = [AccountId: CacheEntry]

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

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
        cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider,
        cryptoAccountsRepository: CryptoAccountsRepository,
        archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider,
        dependenciesFactory: CryptoAccountDependenciesFactory,
        areHDWalletsSupported: Bool
    ) {
        self.userWalletId = userWalletId
        self.cryptoAccountsGlobalStateProvider = cryptoAccountsGlobalStateProvider
        self.cryptoAccountsRepository = cryptoAccountsRepository
        self.archivedCryptoAccountsProvider = archivedCryptoAccountsProvider
        self.dependenciesFactory = dependenciesFactory
        self.areHDWalletsSupported = areHDWalletsSupported
        executor = Executor(label: userWalletId.stringValue)
        criticalSection = Lock(isRecursive: false)
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
        cache.removeAll { removedAccountIds.contains($0.key) } // Also destroys the `didChangeSubscription`s for removed accounts

        return newAccountIds.compactMap { accountId in
            // Early exit if the account is already created and cached
            if let (cachedAccount, _) = cache[accountId] {
                return cachedAccount
            }

            guard let storedCryptoAccount = storedCryptoAccountsKeyedByAccountIds[accountId] else {
                assertionFailure("Stored crypto account not found for accountId: \(accountId)")
                return nil
            }

            guard let accountIcon = AccountModel.Icon(
                rawName: storedCryptoAccount.icon.iconName,
                rawColor: storedCryptoAccount.icon.iconColor
            ) else {
                assertionFailure("Invalid icon for stored crypto account: \(storedCryptoAccount)")
                return nil
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
                derivationManager: dependencies.derivationManager
            )

            dependencies.walletModelsFactoryInput.setCryptoAccount(cryptoAccount)
            dependencies.walletModelsManager.initialize()

            // Updating `cache` within this `compactMap` loop to reduce the number of iterations
            cache[accountId] = (cryptoAccount, makeDidChangeSubscription(for: cryptoAccount))

            return cryptoAccount
        }
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

    private func makeDidChangeSubscription(for cryptoAccount: CommonCryptoAccountModel) -> AnyCancellable {
        return cryptoAccount
            .didChangePublisher
            .withWeakCaptureOf(cryptoAccount)
            .withWeakCaptureOf(self)
            .sink { input in
                let (manager, (cryptoAccount, _)) = input
                manager.saveCryptoAccount(cryptoAccount)
            }
    }

    private func makeConditionsValidator(for flow: ValidationFlow) -> any CryptoAccountConditionsValidator {
        switch flow {
        case .new(let newAccountName, let remoteState):
            return NewCryptoAccountConditionsValidator(newAccountName: newAccountName, remoteState: remoteState)
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

    /// - Note: `cryptoAccountsRepository` has internal synchronization mechanism, therefore this is a `nonisolated` method.
    private nonisolated func saveCryptoAccount(_ cryptoAccount: CommonCryptoAccountModel) {
        let persistentConfig = cryptoAccount.toPersistentConfig()
        cryptoAccountsRepository.updateExistingCryptoAccount(withConfig: persistentConfig)
    }

    private func mapArchiveValidationError(_ error: ArchivedCryptoAccountConditionsValidator.ValidationError) -> AccountArchivationError {
        switch error {
        case .participatesInReferralProgram:
            return .participatesInReferralProgram
        case .unknownError(let underlyingError):
            return .unknownError(underlyingError)
        }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension CommonAccountModelsManager: AccountModelsManager {
    nonisolated var canAddCryptoAccounts: Bool {
        areHDWalletsSupported
    }

    nonisolated var hasArchivedCryptoAccounts: AnyPublisher<Bool, Never> {
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

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountModelsManagerError) {
        guard canAddCryptoAccounts else {
            throw .addingCryptoAccountsNotSupported
        }

        let remoteState: CryptoAccountsRemoteState

        do {
            remoteState = try await cryptoAccountsRepository.getRemoteState()
        } catch {
            AccountsLogger.error("Failed to fetch remote state for user wallet \(userWalletId)", error: error)
            throw .addingCryptoAccountsFailed
        }

        let validator = makeConditionsValidator(for: .new(newAccountName: name, remoteState: remoteState))

        do {
            try await validator.validate()
        } catch {
            AccountsLogger.error("A new account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
            throw .addingCryptoAccountsFailed
        }

        let newAccountConfig = CryptoAccountPersistentConfig(
            derivationIndex: remoteState.nextDerivationIndex,
            name: name,
            icon: icon
        )

        do {
            try await cryptoAccountsRepository.addNewCryptoAccount(withConfig: newAccountConfig, remoteState: remoteState)
        } catch {
            AccountsLogger.error("Failed to add new crypto account for user wallet \(userWalletId)", error: error)
            throw .addingCryptoAccountsFailed
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

    func archiveCryptoAccount(withIdentifier identifier: any AccountModelPersistentIdentifierConvertible) async throws(AccountArchivationError) {
        let validator = makeConditionsValidator(for: .archive(identifier: identifier))

        do {
            try await validator.validate()
        } catch let error as ArchivedCryptoAccountConditionsValidator.ValidationError {
            AccountsLogger.error("A attempt to archive account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)

            let archivationError = mapArchiveValidationError(error)
            throw archivationError
        } catch {
            throw .unknownError(error)
        }

        do {
            try await cryptoAccountsRepository.removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier())
        } catch {
            AccountsLogger.error("Failed to archive existing crypto account with id \(identifier) for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) {
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
            } catch UnarchivedCryptoAccountConditionsValidator.Error.accountHasDuplicatedName {
                let newName = UnarchivedCryptoAccountNameIndexer.makeAccountName(from: info.name)
                info = info.withName(newName)
            } catch UnarchivedCryptoAccountConditionsValidator.Error.tooManyAccounts {
                AccountsLogger.error("A attempt to unarchive account for user wallet \(userWalletId) failed to fulfill the conditions", error: AccountRecoveryError.tooManyActiveAccounts)
                throw .tooManyActiveAccounts
            } catch {
                AccountsLogger.error("A attempt to unarchive account for user wallet \(userWalletId) failed to fulfill the conditions", error: error)
                throw .unknownError(error)
            }
        }

        let persistentConfig = info.toPersistentConfig()

        do {
            try await cryptoAccountsRepository.addNewCryptoAccount(withConfig: persistentConfig, remoteState: remoteState)
        } catch {
            AccountsLogger.error("Failed to unarchive existing crypto account with id \(info.id) for user wallet \(userWalletId)", error: error)
            throw .unknownError(error)
        }
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
        case archive(identifier: any AccountModelPersistentIdentifierConvertible)
        case unarchive(info: ArchivedCryptoAccountInfo, remoteState: CryptoAccountsRemoteState)
    }
}
