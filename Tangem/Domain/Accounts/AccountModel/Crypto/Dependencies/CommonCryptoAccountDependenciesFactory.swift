//
//  CommonCryptoAccountDependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import BlockchainSdk

/// The dependencies of the wallet's own accounts; the joint ones have `CommonJointAccountDependenciesFactory`.
struct CommonCryptoAccountDependenciesFactory {
    let userWalletId: UserWalletId
    /// A single instance per user wallet
    let derivationManager: DerivationManager?
    let derivationStyle: DerivationStyle?
    let keysRepository: KeysRepository
    let cryptoAccountsRepository: CommonCryptoAccountsRepository
    let walletFactory: AnyWalletFactory
    let walletManagerFactory: AnyWalletManagerFactory
    let existingCurves: [EllipticCurve]
    let persistentBlockchains: [TokenItem]
    let hardwareLimitationsUtil: HardwareLimitationsUtil
    let areHDWalletsSupported: Bool
    let shouldLoadExpressAvailability: Bool
    let walletModelsFactoryProvider: WalletModelsFactoryProvider
}

// MARK: - CryptoAccountDependenciesFactory protocol conformance

extension CommonCryptoAccountDependenciesFactory: CryptoAccountDependenciesFactory {
    func makeDependencies(
        forAccountWithDerivationIdentity derivationIdentity: CryptoAccountDerivationIdentity
    ) -> CryptoAccountDependencies {
        assert(
            derivationIdentity.type == .crypto,
            "CommonCryptoAccountDependenciesFactory is supposed to be used only for crypto account dependencies"
        )

        let derivationPathBuilder = CryptoAccountDerivationPathBuilder(
            derivationIndex: derivationIdentity.derivationIndex,
            derivationStyle: derivationStyle
        )

        let userTokensRepository = UserTokensRepositoryAdapter(
            innerRepository: cryptoAccountsRepository,
            derivationIdentity: derivationIdentity
        )

        let userTokensManager = CommonUserTokensManager(
            userWalletId: userWalletId,
            userTokensRepository: userTokensRepository,
            derivationPathBuilder: derivationPathBuilder,
            existingCurves: existingCurves,
            persistentBlockchains: persistentBlockchains,
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
