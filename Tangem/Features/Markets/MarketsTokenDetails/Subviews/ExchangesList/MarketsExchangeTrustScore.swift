//
//  MarketsExchangeTrustScore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemLocalization

enum MarketsExchangeTrustScore: Int, Decodable {
    case risky = 0
    case caution = 4
    case trusted = 8

    init(rawValue: Int?) {
        switch rawValue {
        case .none, .some(0 ... 3):
            self = .risky
        case .some(4 ... 7):
            self = .caution
        case .some(8...):
            self = .trusted
        default:
            self = .risky
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let scoreInt = try container.decode(Int.self)
        self = MarketsExchangeTrustScore(rawValue: scoreInt)
    }

    var title: String {
        switch self {
        case .risky: Localization.marketsTokenDetailsExchangeTrustScoreRisky
        case .caution: Localization.marketsTokenDetailsExchangeTrustScoreCaution
        case .trusted: Localization.marketsTokenDetailsExchangeTrustScoreTrusted
        }
    }
}
