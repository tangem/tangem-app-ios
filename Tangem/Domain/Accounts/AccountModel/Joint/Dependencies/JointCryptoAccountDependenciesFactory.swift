//
//  JointCryptoAccountDependenciesFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import BlockchainSdk

struct JointCryptoAccountDependenciesFactory {
    let userWalletId: UserWalletId
    /// A single instance per user wallet
    let derivationManager: DerivationManager?
    let keysRepository: KeysRepository
    let cryptoAccountsRepository: CommonCryptoAccountsRepository
    let jointAccountsRepository: JointAccountsRepository
    /// A joint account signs with the wallet's own keys; only where the funds live differs.
    let defaultWalletFactory: AnyWalletFactory
    let walletManagerFactory: AnyWalletManagerFactory
    let existingCurves: [EllipticCurve]
    let hardwareLimitationsUtil: HardwareLimitationsUtil
    let shouldLoadExpressAvailability: Bool
    let walletModelsFactoryProvider: WalletModelsFactoryProvider
}

// MARK: - CryptoAccountDependenciesFactory protocol conformance

extension JointCryptoAccountDependenciesFactory: CryptoAccountDependenciesFactory {
    func makeDependencies(
        forAccountWithDerivationIdentity derivationIdentity: CryptoAccountDerivationIdentity
    ) -> CryptoAccountDependencies {
        assert(
            derivationIdentity.type == .joint,
            "JointCryptoAccountDependenciesFactory is supposed to be used only for joint account dependencies"
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

        return CryptoAccountDependencies(
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager,
            walletModelsFactoryInput: wrappedWalletModelsFactory,
            derivationManager: accountSpecificDerivationManager,
        )
    }
}
