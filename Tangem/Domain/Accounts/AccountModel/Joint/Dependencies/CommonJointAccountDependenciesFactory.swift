//
//  CommonJointAccountDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import BlockchainSdk

/// The dependencies of the wallet's joint accounts; its own ones have `CommonCryptoAccountDependenciesFactory`.
/// - Note: The two factories repeat the assembly of the managers on purpose; what they build it out of is what tells
/// the kinds apart.
struct CommonJointAccountDependenciesFactory {
    let userWalletId: UserWalletId
    let configProvider: UserWalletConfigProvider
    /// A single instance per user wallet
    let derivationManager: DerivationManager?
    let keysRepository: KeysRepository
    let cryptoAccountsRepository: CommonCryptoAccountsRepository
    let jointAccountsRepository: JointAccountsRepository
    let jointAccountPendingOperationsRepository: JointAccountPendingOperationsRepository
    let signerFactory: TangemSignerFactory
    /// A joint account signs with the wallet's own keys; only where the funds live differs.
    let defaultWalletFactory: AnyWalletFactory
    let walletManagerFactory: AnyWalletManagerFactory
    let existingCurves: [EllipticCurve]
    let hardwareLimitationsUtil: HardwareLimitationsUtil
    let shouldLoadExpressAvailability: Bool
    let walletModelsFactoryProvider: WalletModelsFactoryProvider
}

// MARK: - JointAccountDependenciesFactory protocol conformance

extension CommonJointAccountDependenciesFactory: JointAccountDependenciesFactory {
    func makeDependencies(
        forAccountWithDerivationIdentity derivationIdentity: CryptoAccountDerivationIdentity
    ) -> JointAccountDependencies {
        assert(
            derivationIdentity.type == .joint,
            "CommonJointAccountDependenciesFactory is supposed to be used only for joint account dependencies"
        )

        let derivationPathBuilder = JointAccountDerivationPathBuilder(derivationIndex: derivationIdentity.derivationIndex)

        let userRoleService = CommonJointAccountUserRoleService(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            keysProvider: keysRepository,
            jointAccountsRepository: jointAccountsRepository
        )

        let statusProvider = CommonJointAccountStatusProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: jointAccountsRepository,
            cryptoAccountsRepository: cryptoAccountsRepository,
            userRoleService: userRoleService
        )

        let userTokensRepository = JointUserTokensRepositoryAdapter(
            innerAdapter: UserTokensRepositoryAdapter(
                innerRepository: cryptoAccountsRepository,
                derivationIdentity: derivationIdentity
            ),
            jointAccountsRepository: jointAccountsRepository,
            safeAddressProvider: statusProvider
        )

        let walletFactory = JointWalletFactory(
            defaultWalletFactory: defaultWalletFactory,
            safeAddressProvider: statusProvider,
            userRoleService: userRoleService
        )

        let userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            configProvider: configProvider,
            userTokensRepository: userTokensRepository,
            derivationPathBuilder: derivationPathBuilder,
            existingCurves: existingCurves,
            // Config-forced blockchains are the wallet's own, not shared with the other members
            persistentBlockchains: [],
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            hardwareLimitationsUtil: hardwareLimitationsUtil
        )

        let walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokensManager: userTokensManager,
            walletFactory: walletFactory,
            walletManagerFactory: walletManagerFactory
        )

        let blockchainSettingsUpdater = CommonBlockchainSettingsUpdater(userTokensRepository: userTokensRepository)
        let walletModelsFactory = walletModelsFactoryProvider.makeWalletModelsFactory(
            blockchainSettingsUpdater: blockchainSettingsUpdater,
            userTokensManager: userTokensManager,
            isSafe: true,
            isEarnSupported: false
        )
        let wrappedWalletModelsFactory = WalletModelsFactoryWrapper(innerFactory: walletModelsFactory)

        let walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: wrappedWalletModelsFactory,
            transactionHistoryUpdater: walletModelsFactoryProvider.transactionHistoryUpdater,
            derivationPathBuilder: derivationPathBuilder
        )

        let pendingDerivationProvider = JointAccountPendingDerivationProvider(
            derivationIndex: derivationIdentity.derivationIndex,
            userTokensManager: userTokensManager,
            keysRepository: keysRepository,
            isDerivationSupported: derivationManager != nil
        )

        userTokensManager.derivationManager = derivationManager
        userTokensManager.walletModelsManager = walletModelsManager

        let membersService = CommonJointAccountMembersService(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: jointAccountsRepository,
            userRoleService: userRoleService
        )

        let pendingOperationsProvider = CommonJointAccountPendingOperationsProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            pendingOperationsRepository: jointAccountPendingOperationsRepository,
            walletModelsManager: walletModelsManager,
            membersService: membersService
        )

        let finishedOperationsWalletUpdater = JointAccountFinishedOperationsWalletUpdater(
            pendingOperationsProvider: pendingOperationsProvider,
            walletModelsManager: walletModelsManager,
            historyDeltaSyncing: walletModelsFactoryProvider.transactionHistoryProviderResolver
        )

        let operationsService = CommonJointAccountOperationsService(
            pendingOperationsRepository: jointAccountPendingOperationsRepository,
            signerFactory: signerFactory
        )

        return JointAccountDependencies(
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager,
            walletModelsFactoryInput: wrappedWalletModelsFactory,
            pendingDerivationProvider: pendingDerivationProvider,
            operationsService: operationsService,
            pendingOperationsProvider: pendingOperationsProvider,
            finishedOperationsWalletUpdater: finishedOperationsWalletUpdater,
            membersService: membersService,
            userRoleService: userRoleService,
            statusProvider: statusProvider
        )
    }
}
