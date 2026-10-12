//
//  MarketsCategoryLocalizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum MarketsCategoryLocalizer {
    static func title(for category: MarketsDTO.Categories.Category) -> String {
        switch category.code {
        case MarketsCategoryCode.realWorldAssets: Localization.commonAll
        case MarketsCategoryCode.xstocks: Localization.marketsRealAssetsCategoryXstocks
        case MarketsCategoryCode.etfs: Localization.marketsRealAssetsCategoryEtfs
        case MarketsCategoryCode.commodities: Localization.marketsRealAssetsCategoryCommodities
        case MarketsCategoryCode.bonds: Localization.marketsRealAssetsCategoryBonds
        case MarketsCategoryCode.stablecoins: Localization.marketsRealAssetsCategoryStablecoins
        default: category.displayName
        }
    }

    static func title(for sector: MarketsDTO.Categories.Sector, in category: MarketsDTO.Categories.Category) -> String {
        guard category.code == MarketsCategoryCode.xstocks,
              let knownSector = MarketsCategoryCode.Sector(rawValue: sector.code) else {
            return sector.displayName
        }

        return switch knownSector {
        case .technology: Localization.marketsRealAssetsSectorXstocksTechnology
        case .financials: Localization.marketsRealAssetsSectorXstocksFinancials
        case .healthcare: Localization.marketsRealAssetsSectorXstocksHealthcare
        case .consumer: Localization.marketsRealAssetsSectorXstocksConsumer
        case .communication: Localization.marketsRealAssetsSectorXstocksCommunication
        case .crypto: Localization.marketsRealAssetsSectorXstocksCrypto
        case .industrials: Localization.marketsRealAssetsSectorXstocksIndustrials
        case .energy: Localization.marketsRealAssetsSectorXstocksEnergy
        }
    }
}
