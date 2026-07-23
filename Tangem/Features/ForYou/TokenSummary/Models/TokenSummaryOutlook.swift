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

    /// Normalized thumb position on the track: 0 = negative (left), 0.5 = neutral (center), 1 = positive (right).
    var position: CGFloat {
        switch self {
        case .negative: 0
        case .neutral: 0.5
        case .positive: 1
        }
    }
}
