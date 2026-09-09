//
//  FeedRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol FeedRoutable: AnyObject {
    func openToken(_ token: MarketsTokenModel)
    func openPulseTagFilter(with input: PulseTagFilterInput)
    func openRealAssetsCategoryFilter(with input: RealAssetsCategoryFilterInput)
    func openEarnNetworksFilter()
    func openEarnTypesFilter()
    func routeOnEarnTokenResolved(_ resolution: EarnTokenResolution, source: EarnOpportunitySource)
    func openPortfolioToken(_ walletModel: any WalletModel)
    func choosePortfolioToken(from walletModels: [any WalletModel])
    func returnToRoot()
}
