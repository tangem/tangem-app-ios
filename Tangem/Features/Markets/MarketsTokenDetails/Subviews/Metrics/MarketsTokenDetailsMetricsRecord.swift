//
//  MarketsTokenDetailsMetricsRecord.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

enum MarketsTokenDetailsMetricsRecordType: String, Identifiable, MarketsTokenDetailsInfoDescriptionProvider {
    case marketCapitalization
    case marketRating
    case tradingVolume
    case fullyDilutedValuation
    case circulatingSupply
    case totalSupply
    case maxSupply

    var id: String { rawValue }

    var titleShort: String {
        switch self {
        case .marketCapitalization: return Localization.marketsTokenDetailsMarketCapitalization
        case .marketRating: return Localization.marketsTokenDetailsMarketRating
        case .tradingVolume: return Localization.marketsTokenDetailsTradingVolume
        case .fullyDilutedValuation: return Localization.marketsTokenDetailsFullyDilutedValuation
        case .circulatingSupply: return Localization.marketsTokenDetailsCirculatingSupply
        case .totalSupply: return Localization.marketsTokenDetailsTotalSupply
        case .maxSupply: return Localization.marketsTokenDetailsMaxSupply
        }
    }

    var titleFull: String {
        switch self {
        case .marketCapitalization: return Localization.marketsTokenDetailsMarketCapitalizationFull
        case .marketRating: return Localization.marketsTokenDetailsMarketRatingFull
        case .tradingVolume: return Localization.marketsTokenDetailsTradingVolumeFull
        case .fullyDilutedValuation: return Localization.marketsTokenDetailsFullyDilutedValuationFull
        case .circulatingSupply: return Localization.marketsTokenDetailsCirculatingSupplyFull
        case .totalSupply: return Localization.marketsTokenDetailsTotalSupplyFull
        case .maxSupply: return Localization.marketsTokenDetailsMaxSupplyFull
        }
    }

    var infoDescription: String {
        switch self {
        case .marketCapitalization: return Localization.marketsTokenDetailsMarketCapitalizationDescription
        case .marketRating: return Localization.marketsTokenDetailsMarketRatingDescription
        case .tradingVolume: return Localization.marketsTokenDetailsTradingVolume24hDescription
        case .fullyDilutedValuation: return Localization.marketsTokenDetailsFullyDilutedValuationDescription
        case .circulatingSupply: return Localization.marketsTokenDetailsCirculatingSupplyDescription
        case .totalSupply: return Localization.marketsTokenDetailsTotalSupplyDescription
        case .maxSupply: return Localization.marketsTokenDetailsMaxSupplyDescription
        }
    }
}

struct MarketsTokenDetailsMetricsRecordInfo: Identifiable {
    let type: MarketsTokenDetailsMetricsRecordType
    let recordData: String
    var recordSubdata: String?

    var id: String {
        "\(type.id) - \(recordData)"
    }

    var title: String {
        type.titleShort
    }
}
