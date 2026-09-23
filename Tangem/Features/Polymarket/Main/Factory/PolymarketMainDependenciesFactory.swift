//
//  PolymarketMainDependenciesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket

struct PolymarketMainDependenciesFactory {
    func make(for userWalletModel: any UserWalletModel) -> PolymarketMainDependencies {
        let walletId = userWalletModel.userWalletId.stringValue
        let apiProvider = PolymarketAPIProviderFactory().makeProvider(walletId: walletId)
        let balanceProvider = CommonPolymarketBalanceProvider(userWalletModel: userWalletModel)

        return PolymarketMainDependencies(
            userWalletModel: userWalletModel,
            apiProvider: apiProvider,
            geoblockStateProvider: CommonPolymarketGeoblockStateProvider(
                geoblockService: PolymarketOnboardingServicesFactory.makeDefault().makeGeoblockService()
            ),
            balanceProvider: balanceProvider,
            accountFundsInteractor: PolymarketAccountFundsFactory().makeInteractor(for: userWalletModel),
            positionsService: PolymarketPositionsFactory().makeService(for: userWalletModel, apiProvider: apiProvider),
            placementService: PolymarketOrderPlacementFactory().makeService(for: userWalletModel),
            clobService: PolymarketOnboardingServicesFactory.makeDefault().makeCLOBService(),
            redeemService: PolymarketRedeemFactory().makeService(for: userWalletModel),
            withdrawContext: PolymarketWithdrawFactory().makeContext(for: userWalletModel),
            fundsArrivalTracker: PolymarketFundsArrivalTracker(
                balancePublisher: balanceProvider.collateralBalancePublisher.map(\.value).eraseToAnyPublisher()
            )
        )
    }
}

// MARK: - PolymarketMainDependencies

struct PolymarketMainDependencies {
    let userWalletModel: any UserWalletModel
    let apiProvider: PolymarketAPIProvider
    let geoblockStateProvider: PolymarketGeoblockStateProvider
    let balanceProvider: PolymarketBalanceProvider
    let accountFundsInteractor: PolymarketAccountFundsInteractor
    let positionsService: PolymarketPositionsService
    let placementService: PolymarketOrderPlacementService
    let clobService: PolymarketCLOBService
    let redeemService: PolymarketRedeeming
    let withdrawContext: PolymarketWithdrawContext
    let fundsArrivalTracker: PolymarketFundsArrivalTracker

    var walletId: String {
        userWalletModel.userWalletId.stringValue
    }

    var accountModel: (any PolymarketAccountModel)? {
        AccountModelsAggregator(.polymarket).model(from: userWalletModel.accountModelsManager)
    }

    var orderAccount: PolymarketOrderAccount? {
        accountModel.map(PolymarketOrderAccount.init(accountModel:))
    }

    var walletModelsProvider: MainScreenUIOrderedWalletModelsProvider {
        MainScreenUIOrderedWalletModelsProvider(userWalletModel: userWalletModel)
    }

    func makeMainViewModel(routable: PolymarketMainRoutable) -> PolymarketMainViewModel {
        PolymarketMainViewModel(
            apiProvider: apiProvider,
            geoblockStateProvider: geoblockStateProvider,
            balanceProvider: balanceProvider,
            accountFundsInteractor: accountFundsInteractor,
            positionsService: positionsService,
            fundsArrivalTracker: fundsArrivalTracker,
            userWalletId: userWalletModel.userWalletId,
            coordinator: routable
        )
    }

    func makeOrderIntent(for request: PolymarketOrderRequest) -> PolymarketOrderIntent {
        switch request {
        case .buy:
            .buy(balance: balanceProvider.collateralBalancePublisher.map(\.value).eraseToAnyPublisher())
        case .sell(let shares):
            .sell(shares: shares)
        }
    }

    func makeSwapParametersFactory(accountModel: any PolymarketAccountModel) -> PolymarketSwapParametersFactory {
        PolymarketSwapParametersFactory(
            userWalletInfo: userWalletModel.userWalletInfo,
            walletModelsProvider: walletModelsProvider,
            accountModel: accountModel
        )
    }
}
