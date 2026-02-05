//
//  TopMarketWidgetRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol TopMarketWidgetRoutable: AnyObject {
    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel)
    func openSeeAllTopMarketWidget()
}
