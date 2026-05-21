//
//  OnrampHistoryMatcher.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum OnrampHistoryMatcher {
    private static let skew: TimeInterval = 10

    public static func findMatch(
        in items: [OnrampHistoryItem],
        since: Date,
        toContractAddress: String,
        toNetwork: String
    ) -> OnrampHistoryItem? {
        let cutoff = since.addingTimeInterval(-skew)
        return items.reduce(into: nil as OnrampHistoryItem?) { best, item in
            guard !item.status.isFailureTerminal,
                  item.createdAt >= cutoff,
                  item.toContractAddress.caseInsensitiveCompare(toContractAddress) == .orderedSame,
                  item.toNetwork.caseInsensitiveCompare(toNetwork) == .orderedSame
            else {
                return
            }
            if let current = best, current.createdAt >= item.createdAt {
                return
            }
            best = item
        }
    }
}
