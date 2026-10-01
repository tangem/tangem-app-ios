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
    /// A single instance per user wallet
    let derivationManager: DerivationManager?
    let keysRepository: KeysRepository
    let cryptoAccountsRepository: CommonCryptoAccountsRepository
    let jointAccountsRepository: JointAccountsRepository
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

        let safeAddressProvider = JointAccountsRepositorySafeAddressProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: jointAccountsRepository,
        )

        let userTokensRepository = JointUserTokensRepositoryAdapter(
            innerAdapter: UserTokensRepositoryAdapter(
                innerRepository: cryptoAccountsRepository,
                derivationIdentity: derivationIdentity
            ),
            jointAccountsRepository: jointAccountsRepository,
            safeAddressProvider: safeAddressProvider
        )

        let walletFactory = JointWalletFactory(
            defaultWalletFactory: defaultWalletFactory,
            safeAddressProvider: safeAddressProvider
        )

        let userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
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
            userTokensManager: userTokensManager
        )
        let wrappedWalletModelsFactory = WalletModelsFactoryWrapper(innerFactory: walletModelsFactory)

        let walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: wrappedWalletModelsFactory,
            derivationPathBuilder: derivationPathBuilder
        )

        // A single instance per unique account, account-specific proxy for `derivationManager`
        let accountSpecificDerivationManager = derivationManager.map { innerDerivationManager in
            return AccountDerivationManager(
                keysRepository: keysRepository,
                userTokensManager: userTokensManager,
                innerDerivationManager: innerDerivationManager
            )
        }

        userTokensManager.derivationManager = accountSpecificDerivationManager
        userTokensManager.walletModelsManager = walletModelsManager

        let membersService = CommonJointAccountMembersService(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: jointAccountsRepository
        )

        let pendingOperationsProvider = CommonJointAccountPendingOperationsProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: jointAccountsRepository,
            walletModelsManager: walletModelsManager
        )

        let finishedOperationsWalletUpdater = JointAccountFinishedOperationsWalletUpdater(
            pendingOperationsProvider: pendingOperationsProvider,
            walletModelsManager: walletModelsManager
        )

        let operationsService = CommonJointAccountOperationsService(
            jointAccountsRepository: jointAccountsRepository,
            signerFactory: signerFactory
        )

        return JointAccountDependencies(
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager,
            walletModelsFactoryInput: wrappedWalletModelsFactory,
            derivationManager: accountSpecificDerivationManager,
            operationsService: operationsService,
            pendingOperationsProvider: pendingOperationsProvider,
            finishedOperationsWalletUpdater: finishedOperationsWalletUpdater,
            membersService: membersService
        )
    }
}
