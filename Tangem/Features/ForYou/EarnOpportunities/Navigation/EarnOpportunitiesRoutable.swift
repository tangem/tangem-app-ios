//
//  EarnOpportunitiesRoutable.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol EarnOpportunitiesRoutable: AnyObject {
    func openEarnStaking(walletModel: any WalletModel, userWalletModel: any UserWalletModel)
    func openEarnYield(walletModel: any WalletModel, userWalletModel: any UserWalletModel)
    func routeEarnSuggestion(_ resolution: EarnTokenResolution)
    func openEarnAddFunds(holdings: [EarnAddFundsHoldingsAggregator.Holding])
    func openSeeAllEarn()
}
