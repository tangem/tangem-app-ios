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

struct CommonCryptoAccountDependenciesFactory {
    typealias UserTokensRepositoryProvider = (_ derivationIndex: Int) -> UserTokensRepository
    typealias WalletModelsFactoryProvider = (_ userWalletId: UserWalletId) -> WalletModelsFactory

    /// A single instance per user wallet
    let derivationManager: DerivationManager?
    let derivationStyle: DerivationStyle?
    let keysRepository: KeysRepository
    let walletManagerFactory: AnyWalletManagerFactory
    let existingCurves: [EllipticCurve]
    let persistentBlockchains: [TokenItem]
    let hardwareLimitationsUtil: HardwareLimitationsUtil
    let areHDWalletsSupported: Bool
    let shouldLoadExpressAvailability: Bool
    let userTokensRepositoryProvider: UserTokensRepositoryProvider
    let walletModelsFactoryProvider: WalletModelsFactoryProvider
}

// MARK: - CryptoAccountDependenciesFactory protocol conformance

extension CommonCryptoAccountDependenciesFactory: CryptoAccountDependenciesFactory {
    func makeDependencies(
        forAccountWithDerivationIndex derivationIndex: Int,
        userWalletId: UserWalletId
    ) -> CryptoAccountDependencies {
        let derivationInfo = AccountsAwareUserTokensManager.DerivationInfo(
            derivationIndex: derivationIndex,
            derivationStyle: derivationStyle,
        )

        let userTokensRepository = userTokensRepositoryProvider(derivationIndex)

        let userTokensManager = AccountsAwareUserTokensManager(
            userWalletId: userWalletId,
            userTokensRepository: userTokensRepository,
            derivationInfo: derivationInfo,
            existingCurves: existingCurves,
            persistentBlockchains: persistentBlockchains,
            shouldLoadExpressAvailability: shouldLoadExpressAvailability,
            hardwareLimitationsUtil: hardwareLimitationsUtil
        )

        let walletManagersRepository = CommonWalletManagersRepository(
            keysProvider: keysRepository,
            userTokensManager: userTokensManager,
            walletManagerFactory: walletManagerFactory
        )

        let walletModelsFactory = walletModelsFactoryProvider(userWalletId)
        let wrappedWalletModelsFactory = AccountsAwareWalletModelsFactoryWrapper(innerFactory: walletModelsFactory)

        let walletModelsManager = CommonWalletModelsManager(
            walletManagersRepository: walletManagersRepository,
            walletModelsFactory: wrappedWalletModelsFactory,
            derivationIndex: derivationIndex,
            derivationStyle: derivationStyle
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
