//
//  PolymarketActivityTab.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket
import TangemUI

enum PolymarketActivityTab: String, CaseIterable, TabNavigationItem {
    case all
    case bought
    case sold
    case fundsAdded
    case withdrawn
    case redeemed
    case lost
    case split

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: Localization.commonAll
        case .bought: Localization.predictionHistoryBought
        case .sold: Localization.predictionHistorySold
        case .fundsAdded: Localization.predictionHistoryFundsAdded
        case .withdrawn: Localization.transactionHistoryWithdrawn
        case .redeemed: Localization.predictionHistoryRedeemed
        case .lost: Localization.predictionPositionsLost
        case .split: Localization.predictionPositionsSplit
        }
    }

    var filter: PolymarketActivityFilter {
        switch self {
        case .all: PolymarketActivityFilter(type: nil, redeemResult: nil)
        case .bought: PolymarketActivityFilter(type: .buy, redeemResult: nil)
        case .sold: PolymarketActivityFilter(type: .sell, redeemResult: nil)
        case .fundsAdded: PolymarketActivityFilter(type: .deposit, redeemResult: nil)
        case .withdrawn: PolymarketActivityFilter(type: .withdraw, redeemResult: nil)
        case .redeemed: PolymarketActivityFilter(type: .redeem, redeemResult: .won)
        case .lost: PolymarketActivityFilter(type: .redeem, redeemResult: .lost)
        case .split: PolymarketActivityFilter(type: .redeem, redeemResult: .split)
        }
    }

    var emptyMessage: String {
        switch self {
        case .all: Localization.predictionHistoryEmpty
        case .bought, .sold, .fundsAdded, .withdrawn, .redeemed, .lost, .split: Localization.commonNoResults
        }
    }

    var offersExploring: Bool {
        self == .all
    }
}
