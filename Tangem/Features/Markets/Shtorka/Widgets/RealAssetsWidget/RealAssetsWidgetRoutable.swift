//
//  RealAssetsWidgetRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol RealAssetsWidgetRoutable: AnyObject {
    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel)
    func openRealAssetsCategoryFilter(with input: RealAssetsCategoryFilterInput)
}
