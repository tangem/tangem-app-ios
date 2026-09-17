//
//  MainScreenDeeplinkRoutableSpy.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@testable import Tangem

final class MainScreenDeeplinkRoutableSpy: MainScreenDeeplinkRoutable {
    var isRootVisible = true
    var isShtorkaPresented = false

    private(set) var openedMarketsTokenId: String?
    private(set) var didOpenBuy = false
    private(set) var swapParameters: PredefinedSwapParameters?
    private(set) var openedCampaignKey: String?

    func openMarketsTokenDetails(tokenModel: MarketsTokenModel) {
        openedMarketsTokenId = tokenModel.id
    }

    func openBuy(userWalletModel: any UserWalletModel) {
        didOpenBuy = true
    }

    func openSwap(parameters: PredefinedSwapParameters) {
        swapParameters = parameters
    }

    func openTokenDetails(
        for walletModel: any WalletModel,
        userWalletModel: UserWalletModel,
        pendingTransactionDetails: PendingTransactionDetails?
    ) {}
    func openTangemPayCampaign(campaignKey: String) {
        openedCampaignKey = campaignKey
    }

    func openStaking(options: StakingDetailsCoordinator.Options) {}
    func openSell(userWalletModel: any UserWalletModel) {}
    func openGetTangemPay(source: TangemPayOnboardingSource, availableSelection: TangemPayWalletSelectionType) {}
    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory) {}
    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory) {}
    func openTangemPayMainView(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        userWalletModel: any UserWalletModel,
        openingAction: TangemPayOpeningAction?
    ) {}
    func openTangemPaySelectPlan(tariffPlanSelector: any TangemPayTariffPlanSelector, userWalletModel: any UserWalletModel) {}
}
