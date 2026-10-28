//
//  CollectiblesAccountModelsRegistry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation
import TangemLocalization

actor CollectiblesAccountModelsRegistry {
    private let dependenciesFactory: DependenciesFactory
    private var cache: CommonCollectiblesAccountModel?
    private var accountListUpdater: AccountListUpdater?

    init(dependenciesFactory: DependenciesFactory) {
        self.dependenciesFactory = dependenciesFactory
    }

    func collectiblesAccountModels(from storedCryptoAccounts: [StoredCryptoAccount]) -> [any CollectiblesAccountModel] {
        assert(
            storedCryptoAccounts.allSatisfy { $0.derivationIdentity.type == .collectibles },
            "CollectiblesAccountModelsRegistry expects only the collectibles entries of the account list"
        )

        guard FeatureProvider.isAvailable(.collectibles) else {
            return []
        }

        let accountModel = cachedOrNewAccountModel()
        accountListUpdater?.update(isInAccountList: storedCryptoAccounts.isNotEmpty)

        return [accountModel]
    }
}

// MARK: - Private logic

private extension CollectiblesAccountModelsRegistry {
    func cachedOrNewAccountModel() -> CommonCollectiblesAccountModel {
        if let cache {
            return cache
        }

        let dependencies = dependenciesFactory.make()
        let accountModel = makeAccountModel(dependencies: dependencies)

        cache = accountModel
        accountListUpdater = makeAccountListUpdater(dependencies: dependencies)

        return accountModel
    }

    func makeAccountModel(dependencies: Dependencies) -> CommonCollectiblesAccountModel {
        CommonCollectiblesAccountModel(
            manager: dependencies.manager,
            name: Localization.collectiblesMainTitle,
            balanceService: dependencies.balanceService,
            buybackSigningLimits: dependencies.buybackSigningLimits
        )
    }

    func makeAccountListUpdater(dependencies: Dependencies) -> AccountListUpdater {
        AccountListUpdater(
            vaultStatePublisher: dependencies.manager.statePublisher,
            canAddToAccountList: FeatureProvider.isAvailable(.jointAccounts),
            addToAccountList: { [accountListWriter = dependencies.accountListWriter] config in
                runTask {
                    await accountListWriter.add(config)
                }
            }
        )
    }
}
