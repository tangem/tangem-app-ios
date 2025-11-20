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
            walletModelsFactory: wrappedWalletModelsFactory
        )

        let derivationManager = areHDWalletsSupported
            ? CommonDerivationManager(keysRepository: keysRepository, userTokensManager: userTokensManager)
            : nil

        userTokensManager.derivationManager = derivationManager
        userTokensManager.walletModelsManager = walletModelsManager
        userTokensManager.sync {}

        return CryptoAccountDependencies(
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager,
            walletModelsFactoryInput: wrappedWalletModelsFactory,
            derivationManager: derivationManager
        )
    }
}
