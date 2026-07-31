//
//  EarnOpportunitiesRoutable.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol EarnOpportunitiesRoutable: AnyObject {
    func openEarnStaking(walletModel: any WalletModel, userWalletModel: any UserWalletModel)
    func openEarnYield(walletModel: any WalletModel, userWalletModel: any UserWalletModel)
    func routeEarnSuggestion(_ resolution: EarnTokenResolution)
    func openSeeAllEarn()
}
