//
//  OnrampHistoryMatcher.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum OnrampHistoryMatcher {
    /// Picks the candidate whose `createdAt` is closest to `since` (the moment the purchase was started).
    /// - Parameter excludingTxIds: history items already attributed to another pending record; lets callers that
    ///   resolve several records against one history page match one-to-one instead of all to the newest item.
    public static func findMatch(
        in records: [OnrampTransaction],
        since: Date,
        toContractAddress: String,
        toNetwork: String,
        providerId: ExpressProvider.Id,
        excludingTxIds: Set<String> = []
    ) -> OnrampTransaction? {
        let lowerBound = since.addingTimeInterval(-Constants.skew)
        let upperBound = since.addingTimeInterval(Constants.matchWindow + Constants.skew)
        return records.reduce(into: nil as OnrampTransaction?) { best, record in
            guard !record.status.isFailureTerminal,
                  !excludingTxIds.contains(record.txId),
                  record.providerId == providerId,
                  record.createdAt >= lowerBound,
                  record.createdAt <= upperBound,
                  record.to.currency.contractAddress.caseInsensitiveCompare(toContractAddress) == .orderedSame,
                  record.to.currency.network.caseInsensitiveCompare(toNetwork) == .orderedSame
            else {
                return
            }
            if let current = best, distance(from: since, to: current.createdAt) <= distance(from: since, to: record.createdAt) {
                return
            }
            best = record
        }
    }

    private static func distance(from since: Date, to createdAt: Date) -> TimeInterval {
        abs(createdAt.timeIntervalSince(since))
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
