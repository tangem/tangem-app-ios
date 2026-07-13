//
//  PriceAlertsWatchlistItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct PriceAlertsWatchlistItemViewModel: Identifiable {
    let id: PriceAlertTokenId
    let name: String
    let symbol: String
    let iconURL: URL
    let priceText: String
    let priceChangeState: PriceChangeView.State
}
