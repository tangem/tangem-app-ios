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

        /// Adds a specified number of milliseconds to the timestamp
        /// - Parameter millisToAdd: The number of milliseconds to add
        /// - Returns: A new timestamp with the added milliseconds, or nil if the result is negative
        func plusMillis(_ millisToAdd: Int64) -> TimeStamp? {
            return Self.from(millis + millisToAdd)
        }

        func plusMillisUnsafe(_ millisToAdd: Int64) -> TimeStamp {
            return Self.unsafe(millis + millisToAdd)
        }

        func plusSeconds(_ secondsToAdd: Int64) -> TimeStamp? {
            return Self.from(millis + secondsToAdd * 1000)
        }

        func plusSecondsUnsafe(_ secondsToAdd: Int64) -> TimeStamp {
            return Self.unsafe(millis + secondsToAdd * 1000)
        }

        func plusMinutes(_ minutesToAdd: Int64) -> TimeStamp? {
            return Self.from(millis + minutesToAdd * 60000)
        }

        func plusMinutesUnsafe(_ minutesToAdd: Int64) -> TimeStamp {
            return Self.unsafe(millis + minutesToAdd * 60000)
        }

        func plusHours(_ hoursToAdd: Int64) -> TimeStamp? {
            return Self.from(millis + hoursToAdd * 3600000)
        }

        func plusHoursUnsafe(_ hoursToAdd: Int64) -> TimeStamp {
            return Self.unsafe(millis + hoursToAdd * 3600000)
        }

        func plusUnsafe(duration: Duration) -> TimeStamp {
            return Self.unsafe(millis + duration.millis)
        }

        static func + (lhs: TimeStamp, rhs: Duration) -> TimeStamp {
            return unsafe(lhs.millis + rhs.millis)
        }

        static func - (lhs: TimeStamp, rhs: Duration) -> TimeStamp? {
            return from(lhs.millis - rhs.millis)
        }

        func minusUnsafe(duration: Duration) -> TimeStamp {
            return Self.unsafe(millis - duration.millis)
        }

        static func - (lhs: TimeStamp, rhs: TimeStamp) -> ALPH.Duration? {
            return ALPH.Duration(millis: lhs.millis - rhs.millis)
        }

        func deltaUnsafe(another: TimeStamp) -> ALPH.Duration {
            (try? ALPH.Duration(unsafeMillis: millis - another.millis)) ?? .zero
        }

        func isBefore(another: TimeStamp) -> Bool {
            return millis < another.millis
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
