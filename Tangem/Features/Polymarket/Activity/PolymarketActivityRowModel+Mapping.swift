//
//  PolymarketActivityRowModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemAssets
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI

extension PolymarketActivityRow.Model {
    static func make(record: PolymarketActivityRecord) -> PolymarketActivityRow.Model {
        PolymarketActivityRow.Model(
            id: record.id,
            icon: icon(for: record),
            title: title(for: record),
            subtitle: subtitle(for: record),
            amount: amount(for: record),
            tone: tone(for: record),
            truncatesSubtitleInMiddle: record.type.isFunding
        )
    }

    static func iconURL(for record: PolymarketActivityRecord) -> URL? {
        let market = record.market

        return market?.iconURL ?? market?.imageURL ?? market?.event?.iconURL ?? market?.event?.imageURL
    }

    static func marketTitle(for record: PolymarketActivityRecord) -> String? {
        record.market?.title?.nilIfEmpty ?? record.market?.event?.title.nilIfEmpty
    }

    static func amount(for record: PolymarketActivityRecord) -> String {
        let displayed = PolymarketOrderFormatter.displayedMoney(record.amount)

        guard displayed > 0 else { return Constants.noAmount }

        let sign = record.type.isIncoming ? String.plusSign : String.minusSign

        return "\(sign) \(PolymarketOrderFormatter.money(displayed))"
    }
}

// MARK: - Fields

private extension PolymarketActivityRow.Model {
    static func icon(for record: PolymarketActivityRecord) -> PolymarketActivityRow.Icon {
        switch record.type {
        case .deposit: .glyph(DesignSystem.Icons.ArrowDown.regular20)
        case .withdraw: .glyph(DesignSystem.Icons.ArrowUp.regular20)
        case .buy, .sell, .redeem: .market(iconURL(for: record))
        }
    }

    static func title(for record: PolymarketActivityRecord) -> String {
        switch record.type {
        case .deposit: Localization.predictionHistoryFundsAdded
        case .withdraw: Localization.transactionHistoryWithdrawn
        case .buy: Localization.predictionHistoryBought
        case .sell: Localization.predictionHistorySold
        case .redeem: redeemTitle(for: record.redeemResult)
        }
    }

    static func redeemTitle(for result: PolymarketRedeemResult?) -> String {
        switch result {
        case .lost: Localization.predictionPositionsLost
        case .split: Localization.predictionPositionsSplit
        case .won, .none: Localization.predictionHistoryRedeemed
        }
    }

    static func subtitle(for record: PolymarketActivityRecord) -> String? {
        guard !record.type.isFunding else { return record.transactionHash?.nilIfEmpty }

        guard let title = marketTitle(for: record) else { return nil }

        guard record.type == .redeem, record.redeemResult == .won else { return title }

        // [REDACTED_TODO_COMMENT]
        return "Because had won in “\(title)”"
    }

    static func tone(for record: PolymarketActivityRecord) -> PolymarketValueTone {
        guard record.type == .redeem, record.amount > 0 else { return .neutral }

        switch record.redeemResult {
        case .won, .none: return .positive
        case .lost, .split: return .neutral
        }
    }
}

// MARK: - Constants

private extension PolymarketActivityRow.Model {
    enum Constants {
        static let noAmount = "-"
    }
}

// MARK: - Funding

private extension PolymarketActivityType {
    var isFunding: Bool {
        self == .deposit || self == .withdraw
    }
}
