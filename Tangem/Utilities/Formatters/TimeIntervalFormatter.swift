//
//  TimeIntervalFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct TimeIntervalFormatter {
    func formattedMinutesOrSeconds(from seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 60 ? [.minute] : [.second]
        formatter.unitsStyle = .short
        return formatter.string(from: seconds) ?? ""
    }
}
