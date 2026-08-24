//
//  TokenSummaryOutlook.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum TokenSummaryOutlook {
    case positive
    case neutral
    case negative

    var title: String {
        switch self {
        case .positive: Localization.tokenSummaryPositiveOutlookTitle
        case .neutral: Localization.tokenSummaryNeutralOutlookTitle
        case .negative: Localization.tokenSummaryNegativeOutlookTitle
        }
    }
}

struct TokenSummaryScore: Equatable {
    let value: Int
    let count: Int

    var outlook: TokenSummaryOutlook {
        let neutralThreshold = count >= 4 ? 2 : 0

        if value > neutralThreshold {
            return .positive
        }

        if value < -neutralThreshold {
            return .negative
        }

        return .neutral
    }

    var normalizedPosition: Double {
        Double(value + count) / Double(2 * count)
    }
}

enum TokenSummaryGaugeState: Equatable {
    case score(TokenSummaryScore)
    case outlookUnavailable
    case dataUnavailable

    var score: TokenSummaryScore? {
        switch self {
        case .score(let score): score
        case .outlookUnavailable, .dataUnavailable: nil
        }
    }

    /// The gauge stands empty in both unavailable states, so only the wording tells them apart.
    var unavailabilityMessage: String? {
        switch self {
        case .score: nil
        case .outlookUnavailable: Localization.tokenSummaryOutlookIsNotAvailable
        case .dataUnavailable: Localization.tokenSummaryCanNotLoadToken
        }
    }
}
