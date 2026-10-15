//
//  PolymarketActivityDetailsModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketActivityDetailsView.Model {
    static func make(record: PolymarketActivityRecord) -> Self {
        let row = PolymarketActivityRow.Model.make(record: record)

        return Self(
            title: row.title,
            date: date(record.occurredAt),
            icon: row.icon,
            headlines: headlines(for: record),
            question: PolymarketActivityRow.Model.marketTitle(for: record),
            outcome: outcome(for: record),
            rows: rows(for: record)
        )
    }
}

// MARK: - Private implementation

private extension PolymarketActivityDetailsView.Model {
    static func date(_ date: Date) -> String {
        "\(dayFormatter.string(from: date)) \(AppConstants.dotSign) \(timeFormatter.string(from: date))"
    }

    static func headlines(for record: PolymarketActivityRecord) -> [String] {
        let amount = PolymarketActivityRow.Model.amount(for: record)

        guard record.type == .redeem else { return [amount] }

        switch record.redeemResult {
        case .lost:
            // [REDACTED_TODO_COMMENT]
            return ["Your Prediction Loss"]
        case .split:
            let money = PolymarketOrderFormatter.money(PolymarketOrderFormatter.displayedMoney(record.amount))
            return [Localization.predictionPositionResultSplitTitle(money)]
        case .won:
            // [REDACTED_TODO_COMMENT]
            return ["Your Prediction Won", amount]
        case .none:
            return [amount]
        }
    }

    static func outcome(for record: PolymarketActivityRecord) -> PolymarketActivityDetailsView.Outcome? {
        guard let market = record.market, let title = market.outcome?.nilIfEmpty else { return nil }

        return PolymarketActivityDetailsView.Outcome(
            title: title,
            style: PolymarketOutcomeStyle(outcomeIndex: market.outcomeIndex, name: title)
        )
    }

    static func rows(for record: PolymarketActivityRecord) -> [PolymarketDetailsRowsBlock.Row] {
        guard record.type == .buy || record.type == .sell, let market = record.market else { return [] }

        var rows: [PolymarketDetailsRowsBlock.Row] = [
            .init(title: Localization.predictionPositionsQuantity, value: PolymarketOrderFormatter.shares(market.shares)),
        ]

        guard let order = record.order else { return rows }

        // [REDACTED_TODO_COMMENT]
        rows.append(.init(title: "Price", value: PolymarketOrderFormatter.money(order.averagePrice)))
        rows.append(.init(title: Localization.predictionPlaceFee, value: PolymarketOrderFormatter.money(order.fee)))
        // [REDACTED_TODO_COMMENT]
        rows.append(.init(title: "Notional Gross", value: PolymarketOrderFormatter.money(order.notional)))

        return rows
    }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
