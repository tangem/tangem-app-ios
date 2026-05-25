//
//  TokenDetailsMarketPriceViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemLocalization
import struct TangemUI.PriceChangeView

struct TokenDetailsMarketPriceViewModel: Equatable {
    let title = Localization.marketsCommonMarketPrice
    let subtitle: String
    let priceChange: PriceChangeView.State
    var miniChartPoints: LoadingResult<[Double], Never>
    @IgnoredEquatable private(set) var action: () -> Void
}
