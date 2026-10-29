//
//  PolymarketActivityCSV.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket

enum PolymarketActivityCSV {
    static func make(records: [PolymarketActivityRecord]) -> String {
        let lines = [Constants.header] + records.map(line(for:))

        return lines
            .map { $0.joined(separator: Constants.separator) }
            .joined(separator: Constants.lineBreak)
    }

    static func write(records: [PolymarketActivityRecord]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(Constants.fileName)
        try make(records: records).write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

// MARK: - Private implementation

private extension PolymarketActivityCSV {
    static func line(for record: PolymarketActivityRecord) -> [String] {
        let market = record.market
        let order = record.order

        return [
            number(dateFormatter.string(from: record.occurredAt)),
            number(record.type.rawValue),
            number(record.redeemResult?.rawValue),
            number(signedAmount(record)),
            text(market?.title),
            text(market?.event?.title),
            text(market?.outcome),
            number(market.map { "\($0.shares)" }),
            number(order.map { "\($0.averagePrice)" }),
            number(order.map { "\($0.platformFee)" }),
            number(order.map { "\($0.builderFee)" }),
            number(order.map { "\($0.notional)" }),
            number(record.transactionHash),
        ]
    }

    static func signedAmount(_ record: PolymarketActivityRecord) -> String {
        guard !record.type.isIncoming, record.amount > 0 else { return "\(record.amount)" }

        return "-\(record.amount)"
    }

    static func number(_ value: String?) -> String {
        quoted(value ?? "")
    }

    static func text(_ value: String?) -> String {
        let value = value ?? ""

        guard let first = value.first, Constants.formulaPrefixes.contains(first) else { return quoted(value) }

        return quoted("'\(value)")
    }

    static func quoted(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    enum Constants {
        static let fileName = "predictions-history.csv"
        static let separator = ","
        static let lineBreak = "\r\n"
        static let formulaPrefixes: Set<Character> = ["=", "+", "-", "@", "\t", "\r"]
        // [REDACTED_TODO_COMMENT]
        static let header = [
            "Date",
            Localization.commonType,
            "Result",
            Localization.commonAmount,
            "Market",
            "Event",
            Localization.predictionPositionsOutcome,
            Localization.predictionPositionsQuantity,
            "Average price",
            "Polymarket fee",
            "Tangem fee",
            "Notional",
            "Transaction hash",
        ]
    }
}
