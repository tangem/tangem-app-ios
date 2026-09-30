//
//  CollectiblesAccountBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemCollectibles
import TangemLocalization

/// Assembles the collectibles account model for one wallet. Takes factories rather than the wallet model:
/// a model built once but read for as long as the wallet lives would freeze the card state and SDK
/// configuration it was created with.
struct CollectiblesAccountBuilder {
    private let userWalletId: UserWalletId
    private let config: UserWalletConfig
    private let keysRepository: KeysRepository
    private let coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory

    init(
        userWalletId: UserWalletId,
        config: UserWalletConfig,
        keysRepository: KeysRepository,
        coldKeyInteractorFactory: any CollectiblesColdKeyInteractorFactory
    ) {
        self.userWalletId = userWalletId
        self.config = config
        self.keysRepository = keysRepository
        self.coldKeyInteractorFactory = coldKeyInteractorFactory
    }

    func buildAccountModel() -> any CollectiblesAccountModel {
        // One provider for the whole model, so the vault read, the config read and every send share the
        // service this wallet already built rather than each resolving the endpoint again
        let serviceProvider = CommonCollectiblesChainServiceProvider()
        let chainReader = CommonCollectiblesChainReader(serviceProvider: serviceProvider)

        let balanceService = CommonCollectiblesBalanceService(
            tokenBalancesRepository: CommonTokenBalancesRepository(userWalletId: userWalletId)
        )

        let manager = CollectiblesManager(
            userWalletId: userWalletId,
            coldOwnerProvider: CommonCollectiblesColdOwnerProvider(keysRepository: keysRepository, derivationStyle: config.derivationStyle),
            vaultReader: chainReader,
            configReader: chainReader,
            vaultUsdcReader: chainReader,
            balanceUpdater: balanceService,
            sessionKeySigner: CommonCollectiblesSessionKeySigner(userWalletId: userWalletId),
            coldKeyInteractorFactory: coldKeyInteractorFactory,
            serviceProvider: serviceProvider,
            presenceStore: StoredCollectiblesAccountPresenceStore.appSettings()
        )

        return CommonCollectiblesAccountModel(
            manager: manager,
            name: Localization.collectiblesMainTitle,
            balanceService: balanceService
        )
    }
}
