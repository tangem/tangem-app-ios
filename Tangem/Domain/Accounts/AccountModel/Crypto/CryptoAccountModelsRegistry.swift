//
//  CryptoAccountModelsRegistry.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Builds a model per stored entry of the wallet's own accounts and keeps it across the reads of the account list:
/// a cached one is brought in step with its entry, one whose entry is gone is disposed of.
/// - Note: Runs on an executor of its own, since building a model builds its wallet managers too.
actor CryptoAccountModelsRegistry {
    private typealias AccountId = CryptoAccountModelId
    private typealias Cache = [AccountId: CommonCryptoAccountModel]

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    private let userWalletId: UserWalletId
    private let dependenciesFactory: CryptoAccountDependenciesFactory
    private let executor: any SerialExecutor
    private var cache: Cache = [:]

    init(userWalletId: UserWalletId, dependenciesFactory: CryptoAccountDependenciesFactory) {
        self.userWalletId = userWalletId
        self.dependenciesFactory = dependenciesFactory
        executor = SerialDispatchQueueExecutor(label: "CryptoAccountModelsRegistry_\(userWalletId.stringValue)")
    }

    /// - Parameter storedCryptoAccounts: Only the `.crypto` entries of the account list; the caller filters it.
    func cryptoAccountModels(
        from storedCryptoAccounts: [StoredCryptoAccount],
        delegate: CommonCryptoAccountModelDelegate
    ) -> [any CryptoAccountModel] {
        let currentAccountIds = cache.keys.toSet()
        var storedCryptoAccountsKeyedByAccountIds: [AccountId: StoredCryptoAccount] = [:]

        let newAccountIds = storedCryptoAccounts
            .compactMap { storedCryptoAccount in
                let accountId = AccountId(userWalletId: userWalletId, derivationIdentity: storedCryptoAccount.derivationIdentity)

                // Updating the `storedCryptoAccountsKeyedByAccountIds` dict within this `compactMap` loop to reduce the number of iterations
                storedCryptoAccountsKeyedByAccountIds[accountId] = storedCryptoAccount

                return accountId
            }

        let removedAccountIds = currentAccountIds.subtracting(newAccountIds)
        let removedAccounts = cache.filter { removedAccountIds.contains($0.key) }.map { $0.value }
        cache.removeAll { removedAccountIds.contains($0.key) }
        let cachedAccountsIds = cache.keys.toSet() // Snapshot of currently cached account IDs before adding new ones

        removedAccounts.forEach { $0.dispose() }

        let newCryptoAccounts = newAccountIds
            .compactMap { accountId -> CommonCryptoAccountModel? in
                guard let storedCryptoAccount = storedCryptoAccountsKeyedByAccountIds[accountId] else {
                    let message = "Stored crypto account not found for accountId: \(accountId)"
                    AccountsLogger.warning(message)
                    assertionFailure(message)
                    return nil
                }

                guard let accountIcon = AccountModel.CompositeIcon(
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

                let dependencies = dependenciesFactory.makeDependencies(
                    forAccountWithDerivationIdentity: storedCryptoAccount.derivationIdentity
                )
                let balanceProvidingDependencies = dependencies.makeBalanceProvidingDependencies()

                let cryptoAccount = CommonCryptoAccountModel(
                    userWalletId: userWalletId,
                    accountName: storedCryptoAccount.name,
                    accountIcon: accountIcon,
                    derivationIdentity: storedCryptoAccount.derivationIdentity,
                    walletModelsManager: dependencies.walletModelsManager,
                    userTokensManager: dependencies.userTokensManager,
                    accountBalanceProvider: balanceProvidingDependencies.balanceProvider,
                    accountRateProvider: balanceProvidingDependencies.ratesProvider,
                    derivationManager: dependencies.derivationManager,
                    delegate: delegate
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
}
