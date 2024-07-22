//
//  TokenMarketsDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenMarketsDetailsRoutable: AnyObject, MarketsPortfolioContainerRoutable {
    func openURL(_ url: URL)
    func openTokenSelector(with coinModel: CoinModel, with walletDataProvider: MarketsWalletDataProvider)
}
