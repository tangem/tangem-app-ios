//
//  PolymarketMapper.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PolymarketMapper {}

// MARK: - Field helpers

extension PolymarketMapper {
    func status(from raw: String?) -> PolymarketEventStatus {
        guard let raw, !raw.isEmpty else { return .unknown("") }
        return PolymarketEventStatus(apiValue: raw)
    }

    func displayMode(from raw: String?, isNegRisk: Bool) -> PolymarketDisplayMode {
        if let raw, !raw.isEmpty {
            return PolymarketDisplayMode(apiValue: raw)
        }
        return isNegRisk ? .groupedOutcomes : .plainMarkets
    }

    func url(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    func cursor(from raw: String?) -> String? {
        raw?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return isoDate(from: string)
            ?? isoDate(from: Self.internetDateTime(fromSpaceSeparated: string))
            ?? Self.isoDayFormatter.date(from: string)
    }

    func decimal(_ raw: String?, field: String) throws -> Decimal {
        guard let raw else { return 0 }

        guard let value = Decimal(stringValue: raw) else {
            throw PolymarketAPIError.decoding(field: field, value: raw)
        }

        return value
    }
}

// MARK: - Formatters

private extension PolymarketMapper {
    static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let isoFractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let isoDayFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}

// MARK: - Date parsing

private extension PolymarketMapper {
    func isoDate(from string: String?) -> Date? {
        guard let string else { return nil }

        return Self.isoFormatter.date(from: string) ?? Self.isoFractionalFormatter.date(from: string)
    }

    static func internetDateTime(fromSpaceSeparated string: String) -> String? {
        guard string.contains(DateConstants.spaceSeparator) else { return nil }

        let dateTime = string.replacingOccurrences(of: DateConstants.spaceSeparator, with: DateConstants.timeSeparator)

        guard dateTime.range(of: DateConstants.hourOnlyOffsetPattern, options: .regularExpression) != nil else {
            return dateTime
        }

        return dateTime + DateConstants.zeroMinutesOffset
    }
}

// MARK: - Constants

private extension PolymarketMapper {
    enum DateConstants {
        static let spaceSeparator = " "
        static let timeSeparator = "T"
        static let hourOnlyOffsetPattern = "[+-][0-9]{2}$"
        static let zeroMinutesOffset = ":00"
    }
}
