//
//  ForYouPeriodSegment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

struct ForYouPeriodSegment: Identifiable, Hashable {
    let id: String
    let title: String
}

extension ForYouPeriodSegment: TangemSegmentedPickerTextProvider {
    var text: String { title }
}

extension ForYouPeriodSegment {
    static let all: [ForYouPeriodSegment] = [
        ForYouPeriodSegment(id: "day", title: TokenSummaryPeriod.day.title),
        ForYouPeriodSegment(id: "week", title: TokenSummaryPeriod.week.title),
        ForYouPeriodSegment(id: "month", title: TokenSummaryPeriod.month.title),
    ]

    static let initial = ForYouPeriodSegment(id: "day", title: TokenSummaryPeriod.day.title)
}

extension ForYouPeriodSegment {
    var period: TokenSummaryPeriod {
        switch id {
        case "week": .week
        case "month": .month
        default: .day
        }
    }

    var timeframe: TokenSummaryIndicator.Timeframe {
        period.timeframe
    }
}
