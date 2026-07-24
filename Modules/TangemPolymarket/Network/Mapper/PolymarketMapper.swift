//
//  PolymarketMapper.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

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
        // The BFF derives displayMode from negRisk; fall back to the same rule if it's absent.
        return isNegRisk ? .groupedOutcomes : .plainMarkets
    }

    func url(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return Self.isoFormatter.date(from: string) ?? Self.isoFractionalFormatter.date(from: string)
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
}
