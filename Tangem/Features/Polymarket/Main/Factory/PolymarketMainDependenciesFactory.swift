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
import TangemUI

struct PolymarketMainDependenciesFactory {
    func make(for userWalletModel: any UserWalletModel) -> PolymarketMainDependencies {
        let walletId = userWalletModel.userWalletId.stringValue
        let apiProvider = PolymarketAPIProviderFactory().makeProvider(walletId: walletId)
        let balanceProvider = CommonPolymarketBalanceProvider(userWalletModel: userWalletModel)
        let fundsArrivalTracker = PolymarketFundsArrivalTracker(
            balancePublisher: balanceProvider.collateralBalancePublisher.map(\.value).eraseToAnyPublisher()
        )
        let refreshCenter = PolymarketMainRefreshCenter()

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
            fundsArrivalTracker: fundsArrivalTracker,
            refreshCenter: refreshCenter,
            activityHandler: PolymarketMainActivityHandler(fundsArrivalTracker: fundsArrivalTracker, refreshCenter: refreshCenter)
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
    let refreshCenter: PolymarketMainRefreshCenter
    let activityHandler: PolymarketMainActivityHandler

    var walletId: String {
        userWalletModel.userWalletId.stringValue
    }

    var signingButtonType: SigningActionButtonViewType {
        SigningActionButtonViewTypeBuilder().build(config: userWalletModel.config)
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

    @MainActor
    func makeMainViewModel(routable: PolymarketMainScreenRoutable) -> PolymarketMainViewModel {
        PolymarketMainViewModel(
            balanceViewModel: makeBalanceBlockViewModel(routable: routable),
            positionsViewModel: makePositionsBlockViewModel(routable: routable),
            searchViewModel: makeSearchBlockViewModel(routable: routable),
            eventsViewModel: makeEventsBlockViewModel(routable: routable),
            geoblockStateProvider: geoblockStateProvider,
            fundsArrivalTracker: fundsArrivalTracker,
            withdrawTracker: withdrawContext.tracker,
            refreshCenter: refreshCenter,
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

// MARK: - Main screen blocks

private extension PolymarketMainDependencies {
    var isRegionRestricted: () -> Bool {
        { [geoblockStateProvider] in geoblockStateProvider.state.isBlocked }
    }

    func makeBalanceBlockViewModel(routable: PolymarketBalanceBlockRoutable) -> PolymarketBalanceBlockViewModel {
        PolymarketBalanceBlockViewModel(
            balanceProvider: balanceProvider,
            accountFundsInteractor: accountFundsInteractor,
            fundsArrivalTracker: fundsArrivalTracker,
            withdrawalStatePublisher: withdrawContext.tracker.statePublisher,
            isRegionRestricted: isRegionRestricted,
            refreshCenter: refreshCenter,
            routable: routable
        )
    }

    @MainActor
    func makePositionsBlockViewModel(routable: PolymarketPositionsBlockRoutable) -> PolymarketPositionsBlockViewModel {
        PolymarketPositionsBlockViewModel(
            positionsService: positionsService,
            presenceStore: AppSettings.shared,
            userWalletId: userWalletModel.userWalletId,
            refreshCenter: refreshCenter,
            activityHandler: activityHandler,
            routable: routable
        )
    }

    func makeSearchBlockViewModel(routable: PolymarketEventOpeningRoutable) -> PolymarketSearchBlockViewModel {
        PolymarketSearchBlockViewModel(
            apiProvider: apiProvider,
            activityHandler: activityHandler,
            isRegionRestricted: isRegionRestricted,
            routable: routable
        )
    }

    func makeEventsBlockViewModel(routable: PolymarketEventOpeningRoutable) -> PolymarketEventsBlockViewModel {
        PolymarketEventsBlockViewModel(
            apiProvider: apiProvider,
            refreshCenter: refreshCenter,
            activityHandler: activityHandler,
            isRegionRestricted: isRegionRestricted,
            routable: routable
        )
    }
}
