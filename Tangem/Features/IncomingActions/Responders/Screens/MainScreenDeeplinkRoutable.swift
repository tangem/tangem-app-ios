//
//  MainScreenDeeplinkRoutable.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What the main screen can open natively for a deeplink — the very navigation a tap performs.
protocol MainScreenDeeplinkRoutable: AnyObject {
    /// Whether the main screen's own root is on screen rather than behind a screen it pushed. What is
    /// presented over the window is the responder's own question.
    var isRootVisible: Bool { get }

    /// Whether the markets shtorka is up over the root. It is the root's normal company, not something covering it.
    var isShtorkaPresented: Bool { get }

    func openTokenDetails(
        for walletModel: any WalletModel,
        userWalletModel: UserWalletModel,
        pendingTransactionDetails: PendingTransactionDetails?
    )
    func openStaking(options: StakingDetailsCoordinator.Options)
    func openMarketsTokenDetails(tokenModel: MarketsTokenModel)
    func openBuy(userWalletModel: any UserWalletModel)
    func openSell(userWalletModel: any UserWalletModel)
    func openSwap(parameters: PredefinedSwapParameters)
    /// The link itself is carried along: the onboarding validates it before showing the offer, and an offer
    /// reached by a link is not the same offer as one reached by a tap.
    func openGetTangemPay(source: TangemPayOnboardingSource, availableSelection: TangemPayWalletSelectionType)
    func openTangemPayCampaign(campaignKey: String)
    func openYieldModulePromoView(apy: Decimal, factory: YieldModuleFlowFactory)
    func openYieldModuleActiveInfo(factory: YieldModuleFlowFactory)
    func openTangemPayMainView(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        userWalletModel: any UserWalletModel,
        openingAction: TangemPayOpeningAction?
    )
    func openTangemPaySelectPlan(tariffPlanSelector: any TangemPayTariffPlanSelector, userWalletModel: any UserWalletModel)
}
