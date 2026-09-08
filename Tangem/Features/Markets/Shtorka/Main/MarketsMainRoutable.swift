//
//  MarketsMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsMainRoutable: AnyObject, MarketsRoutable, TopMarketWidgetRoutable, PulseMarketWidgetRoutable, NewsWidgetRoutable, EarnWidgetRoutable, RealAssetsWidgetRoutable, MarketsTokenSearchRoutable {
    func openForYou()
    func openPolymarket(for userWalletModels: [any UserWalletModel])
    func openCollectibles(with options: CollectiblesCoordinator.Options)
}
