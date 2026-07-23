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
    // [REDACTED_TODO_COMMENT]
    static let all: [ForYouPeriodSegment] = [
        ForYouPeriodSegment(id: "day", title: "Day"),
        ForYouPeriodSegment(id: "week", title: "Week"),
        ForYouPeriodSegment(id: "month", title: "Month"),
    ]

    static let initial = ForYouPeriodSegment(id: "day", title: "Day")
}
