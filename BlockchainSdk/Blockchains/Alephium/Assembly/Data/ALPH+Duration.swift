//
//  Alephium+Duration.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing a duration in milliseconds
    struct Duration: Comparable, CustomStringConvertible {
        /// The duration in milliseconds
        let millis: Int64

        // MARK: - Initializers

        /// Throwing initializer (for "unsafe" creation)
        init(unsafeMillis: Int64) throws {
            guard unsafeMillis >= 0 else {
                throw DurationError.negativeDuration
            }
            millis = unsafeMillis
        }

        /// Failable initializer (returns nil for negative values)
        init?(millis: Int64) {
            guard millis >= 0 else { return nil }
            self.millis = millis
        }

        // MARK: - Static Properties

        static let zero: Duration = try! Duration(unsafeMillis: 0)

        // MARK: - Computed Properties

        var seconds: Int64 { millis / 1000 }
        var minutes: Int64 { seconds / 60 }
        var hours: Int64 { seconds / 3600 }

        // MARK: - Operations

        func addingUnsafe(_ other: Duration) -> Duration {
            try! Duration(unsafeMillis: millis + other.millis)
        }

        func subtracting(_ other: Duration) -> Duration? {
            Duration(millis: millis - other.millis)
        }

        func multiplied(by scale: Int64) -> Duration? {
            Duration(millis: millis * scale)
        }

        func multipliedUnsafe(by scale: Int64) -> Duration {
            try! Duration(unsafeMillis: millis * scale)
        }

        func divided(by scale: Int64) -> Duration? {
            guard scale != 0 else { return nil }
            return Duration(millis: millis / scale)
        }

        func dividedUnsafe(by scale: Int64) -> Duration {
            try! Duration(unsafeMillis: millis / scale)
        }

        // MARK: - Protocol Conformance

        static func == (lhs: Duration, rhs: Duration) -> Bool {
            lhs.millis == rhs.millis
        }

        static func < (lhs: Duration, rhs: Duration) -> Bool {
            lhs.millis < rhs.millis
        }

        var description: String {
            "Duration(\(millis)ms)"
        }
    }

    enum DurationError: Error {
        case negativeDuration
    }
}
