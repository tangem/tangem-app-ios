//
//  TokenSummaryMetric.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TokenSummaryMetric: Identifiable {
    var id: String { title }
    let kind: TokenSummaryIndicator.Kind
    let title: String
    /// Explanation shown in the bottom sheet opened from the row's info button.
    let info: String
    let content: Content

    enum Content {
        /// A loaded reading: the numeric value plus the sentiment it signals.
        case reading(value: String, sentiment: TokenSummaryOutlook)
        /// The indicator couldn't be loaded for this asset — shown as a lone "None" badge and left out of the gauge.
        case unavailable
    }
}
