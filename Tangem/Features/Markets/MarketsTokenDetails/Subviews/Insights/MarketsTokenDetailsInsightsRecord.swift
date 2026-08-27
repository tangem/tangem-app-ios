//
//  MarketsTokenDetailsInsightsRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum MarketsTokenDetailsInsightsRecordType: String, Identifiable, MarketsTokenDetailsInfoDescriptionProvider {
    case buyers
    case buyPressure
    case holdersChange
    case liquidity

    var id: String { rawValue }

    var titleShort: String {
        switch self {
        case .buyers: return Localization.marketsTokenDetailsExperiencedBuyers
        case .buyPressure: return Localization.marketsTokenDetailsBuyPressure
        case .holdersChange: return Localization.marketsTokenDetailsHolders
        case .liquidity: return Localization.marketsTokenDetailsLiquidity
        }
    }

    var titleFull: String {
        switch self {
        case .buyers: return Localization.marketsTokenDetailsExperiencedBuyersFull
        case .buyPressure: return Localization.marketsTokenDetailsBuyPressureFull
        case .holdersChange: return Localization.marketsTokenDetailsHoldersFull
        case .liquidity: return Localization.marketsTokenDetailsLiquidityFull
        }
    }

    var infoDescription: String {
        switch self {
        case .buyers: return Localization.marketsTokenDetailsExperiencedBuyersDescription
        case .buyPressure: return Localization.marketsTokenDetailsBuyPressureDescription
        case .holdersChange: return Localization.marketsTokenDetailsHoldersDescription
        case .liquidity: return Localization.marketsTokenDetailsLiquidityDescription
        }
    }
}

struct MarketsTokenDetailsInsightsRecordInfo: Identifiable {
    let type: MarketsTokenDetailsInsightsRecordType
    let recordData: String
    let trend: MarketsTokenDetailsStatisticTrend?

    var id: String {
        "\(type.id) - \(recordData)"
    }

    var title: String {
        type.titleShort
    }
}
