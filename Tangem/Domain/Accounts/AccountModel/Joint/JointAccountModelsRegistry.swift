//
//  JointAccountModelsRegistry.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Builds a model per joint account out of the two halves it is kept in, the account list's entry (name, icon, tokens)
/// and the repository's record (status, members, invites), and keeps it across the reads of either, so that a status
/// moving on or a member joining reaches whoever holds the model. The joint counterpart of `CryptoAccountModelsRegistry`.
actor JointAccountModelsRegistry {
    private typealias AccountId = CryptoAccountModelId
    private typealias Cache = [AccountId: CommonJointAccountModel]

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    private let userWalletId: UserWalletId
    private let dependenciesFactory: JointAccountDependenciesFactory
    private let executor: any SerialExecutor
    private var cache: Cache = [:]

    init(userWalletId: UserWalletId, dependenciesFactory: JointAccountDependenciesFactory) {
        self.userWalletId = userWalletId
        self.dependenciesFactory = dependenciesFactory
        executor = SerialDispatchQueueExecutor(label: "JointAccountModelsRegistry_\(userWalletId.stringValue)")
    }

    /// - Parameter storedCryptoAccounts: Only the `.joint` entries of the account list; the caller filters it.
    /// - Note: An account whose record has not arrived yet is not built at all; the list is put together again once it does.
    func jointAccountModels(
        from storedCryptoAccounts: [StoredCryptoAccount],
        with storedJointAccounts: [StoredJointAccount],
        invites storedInvites: [StoredJointAccountInvites],
        delegate: any JointAccountModelDelegate
    ) -> [any JointAccountModel] {
        assert(
            storedCryptoAccounts.allSatisfy { $0.derivationIdentity.type == .joint },
            "JointAccountModelsRegistry is supposed to be given the joint entries of the account list only"
        )

        // Keyed case-insensitively, like every other match on this identifier
        let storedJointAccountsKeyedByCryptoAccountIds = storedJointAccounts.keyedFirst { $0.cryptoAccountId.lowercased() }
        let invitesKeyedByCryptoAccountIds = storedInvites.keyedFirst { $0.cryptoAccountId.lowercased() }

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

        let newJointAccounts = newAccountIds
            .compactMap { accountId -> CommonJointAccountModel? in
                guard let storedCryptoAccount = storedCryptoAccountsKeyedByAccountIds[accountId] else {
                    let message = "Stored crypto account not found for accountId: \(accountId)"
                    AccountsLogger.warning(message)
                    assertionFailure(message)
                    return nil
                }

                let identifier = accountId.rawValue.hexString.lowercased()

                guard let storedJointAccount = storedJointAccountsKeyedByCryptoAccountIds[identifier] else {
                    JointAccountsLogger.warning("Nothing is stored yet for the joint account '\(accountId)'")
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

                let invites = invitesKeyedByCryptoAccountIds[identifier]?.invites ?? []
                let members = storedJointAccount.members.map(member(from:))

                // Early exit if the account is already created and cached
                if let cachedAccount = cache[accountId] {
                    // Update cached account properties in case they were changed remotely
                    return cachedAccount.update { editor in
                        storedCryptoAccount.name.map(editor.setName)
                        editor.setIcon(accountIcon)
                        editor.setStatus(storedJointAccount.status)
                        editor.setMembers(members)
                        editor.setInvites(invites)
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

                let policy = JointAccountPolicy(
                    membersCount: storedJointAccount.membersCount,
                    signersCount: storedJointAccount.threshold
                )

                let jointAccount = CommonJointAccountModel(
                    cryptoAccount: cryptoAccount,
                    derivationIdentity: storedCryptoAccount.derivationIdentity,
                    policy: policy,
                    status: storedJointAccount.status,
                    operationsService: dependencies.operationsService,
                    pendingOperationsProvider: dependencies.pendingOperationsProvider,
                    members: members,
                    invites: invites,
                    delegate: delegate
                )

                // The wallets are handed the joint account rather than the crypto half it wraps, so that whoever holds
                // a wallet can reach the account's operations
                dependencies.walletModelsFactoryInput.setCryptoAccount(jointAccount)
                // Uses `walletModelsFactory` internally, therefore must be initialized after setting the account in `walletModelsFactoryInput`
                dependencies.walletModelsManager.initialize()
                // Updating `cache` within this `compactMap` loop to reduce the number of iterations
                cache[accountId] = jointAccount

                return jointAccount
            }

        // Trigger initial synchronization for all newly created accounts. Creating `newJointAccounts` is performed
        // on a serial executor, so it may take some time if many accounts need to be created.
        for newJointAccount in newJointAccounts where !cachedAccountsIds.contains(newJointAccount.id) {
            newJointAccount.userTokensManager.sync {}
        }

        return newJointAccounts
    }

    private func member(from stored: StoredJointAccount.Member) -> JointAccountMember {
        let role: JointAccountMember.Role = switch stored.role {
        case .creator: .creator
        case .member: .member(inviteId: stored.inviteId)
        }

        return JointAccountMember(name: stored.name, address: stored.address, role: role)
    }
}
