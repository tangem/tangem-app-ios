//
//  OnrampHistoryMatcher.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum OnrampHistoryMatcher {
    public static func findMatch(
        in records: [OnrampTransaction],
        since: Date,
        toContractAddress: String,
        toNetwork: String,
        providerId: ExpressProvider.Id
    ) -> OnrampTransaction? {
        let lowerBound = since.addingTimeInterval(-Constants.skew)
        let upperBound = since.addingTimeInterval(Constants.matchWindow + Constants.skew)
        return records.reduce(into: nil as OnrampTransaction?) { best, record in
            guard !record.status.isFailureTerminal,
                  record.providerId == providerId,
                  record.createdAt >= lowerBound,
                  record.createdAt <= upperBound,
                  record.to.currency.contractAddress.caseInsensitiveCompare(toContractAddress) == .orderedSame,
                  record.to.currency.network.caseInsensitiveCompare(toNetwork) == .orderedSame
            else {
                return
            }
            if let current = best, current.createdAt >= record.createdAt {
                return
            }
            best = record
        }
    }
}

private extension OnrampHistoryMatcher {
    enum Constants {
        /// Tolerance applied to `since` to absorb client/backend clock drift when matching by `createdAt`.
        static let skew: TimeInterval = 10
        /// Upper-bound window past `since` within which a created onramp record is still considered a candidate.
        static let matchWindow: TimeInterval = 15 * 60
    }
}
