//
//  CollectiblesAccountModelsRegistry+Dependencies.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import TangemCollectibles
import BlockchainSdk

extension CollectiblesAccountModelsRegistry {
    struct Dependencies {
        let manager: CollectiblesManager
        let balanceService: any CollectiblesBalanceService
        let buybackSigningLimits: any CollectiblesBuybackSigningLimits
        let accountListWriter: AccountListWriter
    }

    struct DependenciesFactory {
        let userWalletId: UserWalletId
        let derivationStyle: DerivationStyle?
        let keysRepository: KeysRepository
        let cryptoAccountsRepository: any CryptoAccountsRepository
        let coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory
        let buybackSigningLimits: any CollectiblesBuybackSigningLimits

        func make() -> Dependencies {
            let serviceProvider = CommonCollectiblesChainServiceProvider()
            let chainReader = CommonCollectiblesChainReader(serviceProvider: serviceProvider)

            let balanceService = CommonCollectiblesBalanceService(
                tokenBalancesRepository: CommonTokenBalancesRepository(userWalletId: userWalletId)
            )

            let coldOwnerProvider = CommonCollectiblesColdOwnerProvider(
                keysRepository: keysRepository,
                derivationStyle: derivationStyle
            )
            let sessionKeySigner = CommonCollectiblesSessionKeySigner(userWalletId: userWalletId)
            let transactionSender = CollectiblesColdKeyTransactionSender(serviceProvider: serviceProvider)

            let onboardingInteractor = CollectiblesOnboardingInteractor(
                coldOwnerProvider: coldOwnerProvider,
                sessionKeySigner: sessionKeySigner,
                configReader: chainReader,
                coldKeyInteractorFactory: coldKeyInteractorFactory,
                transactionSender: transactionSender
            )

            let purchaseTransactionDispatcher = CollectiblesPurchaseTransactionDispatcher(
                coldOwnerProvider: coldOwnerProvider,
                configReader: chainReader,
                sessionKeySigner: sessionKeySigner,
                transactionSender: transactionSender
            )

            let buybackTransactionDispatcher = CollectiblesBuybackTransactionDispatcher(
                coldOwnerProvider: coldOwnerProvider,
                configReader: chainReader,
                coldKeyInteractorFactory: coldKeyInteractorFactory,
                transactionSender: transactionSender
            )

            let manager = CollectiblesManager(
                userWalletId: userWalletId,
                coldOwnerProvider: coldOwnerProvider,
                vaultReader: chainReader,
                vaultUsdcReader: chainReader,
                balanceUpdater: balanceService,
                sessionKeySigner: sessionKeySigner,
                coldKeyInteractorFactory: coldKeyInteractorFactory,
                transactionSender: transactionSender,
                onboardingInteractor: onboardingInteractor,
                purchaseTransactionDispatcher: purchaseTransactionDispatcher,
                buybackTransactionDispatcher: buybackTransactionDispatcher,
                presenceStore: StoredCollectiblesAccountPresenceStore.appSettings()
            )

            return Dependencies(
                manager: manager,
                balanceService: balanceService,
                buybackSigningLimits: buybackSigningLimits,
                accountListWriter: AccountListWriter(cryptoAccountsRepository: cryptoAccountsRepository)
            )
        }
    }
}
