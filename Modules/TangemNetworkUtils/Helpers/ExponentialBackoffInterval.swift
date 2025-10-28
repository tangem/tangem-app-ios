//
//  ExponentialBackoffInterval.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Provides exponential backoff with random jitter using standard formula `base * pow(2, retryAttempt) ± jitter`.
public struct ExponentialBackoffInterval {
    private let retryAttempt: Int

    public init(retryAttempt: Int) {
        self.retryAttempt = retryAttempt
    }

    public func callAsFunction() -> UInt64 {
        return makeInterval()
    }

    /// - Returns: Retry interval in nanoseconds.
    public func makeInterval() -> UInt64 {
        let retryJitter: TimeInterval = .random(in: Constants.retryJitterMinValue ... Constants.retryJitterMaxValue)
        let retryIntervalSeconds = Constants.retryBaseValue * pow(2.0, TimeInterval(retryAttempt)) + retryJitter

        return UInt64(retryIntervalSeconds * TimeInterval(NSEC_PER_SEC))
    }
}

// MARK: - Constants

private extension ExponentialBackoffInterval {
    enum Constants {
        static var retryBaseValue: TimeInterval { 1.0 }
        static var retryJitterMinValue: TimeInterval { -0.5 }
        static var retryJitterMaxValue: TimeInterval { 0.5 }
    }
}
