//
//  ALPH+TimeStamp.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing a timestamp in the Alephium blockchain
    /// Timestamps are used to track the time of transactions and blocks
    struct TimeStamp: Comparable {
        /// The number of milliseconds since the Unix epoch (January 1, 1970)
        let millis: Int64

        /// Initializes a new timestamp with the given number of milliseconds
        /// - Parameter millis: The number of milliseconds since the Unix epoch
        init(_ millis: Int64) {
            self.millis = millis
        }

        func isZero() -> Bool {
            return millis == 0
        }

        static func + (lhs: TimeStamp, rhs: Duration) -> TimeStamp {
            return unsafe(lhs.millis + rhs.millis)
        }

        static func - (lhs: TimeStamp, rhs: Duration) -> TimeStamp? {
            return from(lhs.millis - rhs.millis)
        }

        static func - (lhs: TimeStamp, rhs: TimeStamp) -> ALPH.Duration? {
            return ALPH.Duration(millis: lhs.millis - rhs.millis)
        }

        static func < (lhs: TimeStamp, rhs: TimeStamp) -> Bool {
            return lhs.millis < rhs.millis
        }

        static func > (lhs: TimeStamp, rhs: TimeStamp) -> Bool {
            return lhs.millis > rhs.millis
        }

        static func == (lhs: TimeStamp, rhs: TimeStamp) -> Bool {
            return lhs.millis == rhs.millis
        }

        static func <= (lhs: TimeStamp, rhs: TimeStamp) -> Bool {
            return lhs.millis <= rhs.millis
        }

        static func >= (lhs: TimeStamp, rhs: TimeStamp) -> Bool {
            return lhs.millis >= rhs.millis
        }

        var description: String {
            return "TimeStamp($millis)ms)"
        }

        static var zero: TimeStamp {
            return unsafe(0)
        }

        static var max: TimeStamp {
            return unsafe(Int64.max)
        }

        static func now() -> TimeStamp {
            return unsafe(Int64(Date().timeIntervalSince1970 * 1000))
        }
    }
}

extension ALPH.TimeStamp {
    private static func from(_ millis: Int64) -> ALPH.TimeStamp? {
        guard millis >= 0 else { return nil }
        return ALPH.TimeStamp(millis)
    }

    private static func unsafe(_ millis: Int64) -> ALPH.TimeStamp {
        precondition(millis >= 0, "Timestamp must be non-negative")
        return ALPH.TimeStamp(millis)
    }
}
