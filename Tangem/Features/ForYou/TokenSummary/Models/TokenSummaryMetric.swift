//
//  TokenSummaryMetric.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TokenSummaryMetric: Identifiable {
    var id: String { title }
    let title: String
    let value: String
    let sentiment: TokenSummaryOutlook
    /// Explanation shown in the bottom sheet opened from the row's info button.
    let info: String
}
