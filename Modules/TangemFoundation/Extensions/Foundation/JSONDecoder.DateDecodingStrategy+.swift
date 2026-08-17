//
//  JSONDecoder.DateDecodingStrategy+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public extension JSONDecoder.DateDecodingStrategy {
    static let customISO8601 = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = DateFormatter.iso8601withFractionalSeconds.date(from: string) ?? DateFormatter.iso8601.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }

    /// - Note: Standard `JSONDecoder.DateDecodingStrategy.iso8601` uses `.withInternetDateTime` format of the
    /// `ISO8601DateFormatter` and won't parse milliseconds, see https://stackoverflow.com/a/46538423 for details.
    static var iso8601WithFractionalSeconds: JSONDecoder.DateDecodingStrategy = {
        let dateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = .posixEnUS

        return .formatted(dateFormatter)
    }()
}

private extension DateFormatter {
    static let iso8601withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
