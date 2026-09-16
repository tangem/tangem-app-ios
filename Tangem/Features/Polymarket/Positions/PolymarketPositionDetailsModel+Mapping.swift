//
//  PolymarketPositionDetailsModel+Mapping.swift
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
import TangemUI

extension PolymarketPositionDetailsView.Model {
    static func make(
        position: PolymarketPosition,
        onClosePosition: @escaping () -> Void,
        onBuy: @escaping () -> Void,
        onHint: @escaping (PolymarketPositionHintSheetView.Model) -> Void,
        isOrderLoading: Bool
    ) -> Self {
        Self(
            header: header(position: position),
            market: market(position: position),
            stats: stats(position: position, onHint: onHint),
            rows: rows(position: position),
            notice: notice(position: position),
            // [REDACTED_TODO_COMMENT]
            secondaryAction: action(title: Localization.commonClose, isEnabled: false, perform: onClosePosition),
            primaryAction: action(
                title: Localization.commonBuy,
                isEnabled: canTrade(position) && !isOrderLoading,
                isLoading: isOrderLoading,
                perform: onBuy
            )
        )
    }
}

// MARK: - Blocks

private extension PolymarketPositionDetailsView.Model {
    static func header(position: PolymarketPosition) -> PolymarketPositionHeader.Model {
        PolymarketPositionHeader.Model(
            iconURL: position.iconURL,
            changeText: changeText(position: position),
            changeType: PriceChangeView.ChangeType(from: position.cashPnl),
            valueText: money(position.currentValue),
            question: question(position: position),
            outcomeTitle: position.outcome,
            outcomeStyle: PolymarketOutcomeStyle(binaryOutcomeName: position.outcome),
            payoutAmount: payoutAmount(position: position)
        )
    }

    static func market(position: PolymarketPosition) -> PolymarketMarketCard.Model {
        PolymarketMarketCard.Model(
            id: position.id,
            title: marketTitle(position: position),
            volumeText: nil,
            imageURL: position.iconURL,
            predictedText: nil,
            outcomes: []
        )
    }

    static func stats(
        position: PolymarketPosition,
        onHint: @escaping (PolymarketPositionHintSheetView.Model) -> Void
    ) -> [PolymarketPositionStatTile.Model] {
        [
            .init(
                id: Constants.quantityTileID,
                caption: Localization.predictionPositionsQuantity,
                value: shares(position.size)
            ),
            .init(
                id: Constants.priceChangeTileID,
                caption: Localization.predictionPositionsPriceChanges,
                value: priceChange(position: position)
            ),
            .init(
                id: Constants.unrealizedTileID,
                caption: Localization.predictionPositionsUnrealizedPnl,
                value: signedMoney(position.cashPnl),
                tone: PolymarketValueTone(position.cashPnl),
                onHintTap: { onHint(.unrealizedPnl) }
            ),
            .init(
                id: Constants.realizedTileID,
                caption: Localization.predictionPositionsRealizedPnl,
                value: signedMoney(position.realizedPnl),
                tone: PolymarketValueTone(position.realizedPnl),
                onHintTap: { onHint(.realizedPnl) }
            ),
        ]
    }

    static func rows(position: PolymarketPosition) -> [PolymarketDetailsRowsBlock.Row] {
        var rows: [PolymarketDetailsRowsBlock.Row] = [
            .init(title: Localization.predictionPositionsInvested, value: money(position.initialValue)),
            .init(title: Localization.predictionPositionsStatus, value: statusText(position: position)),
        ]

        if let endDate = position.endDate {
            rows.append(.init(
                title: Localization.predictionDetailsResolutionDate,
                value: PolymarketOrderResultFormatter.resolutionDay(endDate)
            ))
        }

        return rows
    }

    static func notice(position: PolymarketPosition) -> PolymarketPositionNotice? {
        switch position.resolutionStatus {
        case .pendingResolution, .proposed: .pendingResolution
        case .disputed: .disputed
        case .open, .resolved, .unknown: nil
        }
    }

    static func canTrade(_ position: PolymarketPosition) -> Bool {
        position.isAcceptingOrders && position.marketId != nil && position.eventId != nil
    }

    static func action(
        title: String,
        isEnabled: Bool,
        isLoading: Bool = false,
        perform: @escaping () -> Void
    ) -> PolymarketPositionDetailsView.Action {
        PolymarketPositionDetailsView.Action(title: title, isEnabled: isEnabled, isLoading: isLoading, perform: perform)
    }
}

// MARK: - Values

private extension PolymarketPositionDetailsView.Model {
    static let percentFormatter = PercentFormatter()

    static func question(position: PolymarketPosition) -> String {
        position.title.nilIfEmpty
            ?? position.eventTitle?.nilIfEmpty
            ?? Localization.predictionPositionsUnavailable
    }

    static func marketTitle(position: PolymarketPosition) -> String {
        position.eventTitle?.nilIfEmpty
            ?? position.title.nilIfEmpty
            ?? Localization.predictionPositionsUnavailable
    }

    static func changeText(position: PolymarketPosition) -> String {
        let percent = percentFormatter.format(position.pnlRatio, option: .priceChange)
        let amount = money(abs(position.cashPnl))

        return "\(percent) (\(amount))"
    }

    static func payoutAmount(position: PolymarketPosition) -> String? {
        guard position.settlement == nil else { return nil }

        return money(position.size)
    }

    static func priceChange(position: PolymarketPosition) -> String {
        let from = PolymarketPriceFormatter.centsText(position.avgPrice)
        let to = PolymarketPriceFormatter.centsText(position.curPrice)

        return "\(from) \(Constants.arrow) \(to)"
    }

    static func statusText(position: PolymarketPosition) -> String {
        switch position.resolutionStatus {
        case .open: Localization.predictionPositionsOpen
        case .pendingResolution, .proposed: Localization.predictionPositionsPending
        case .disputed: Localization.predictionPositionsDisputed
        case .resolved, .unknown: settlementText(position: position)
        }
    }

    static func settlementText(position: PolymarketPosition) -> String {
        switch position.settlement {
        case .won: Localization.predictionPositionsWon
        case .lost: Localization.predictionPositionsLost
        case .split: Localization.predictionPositionsSplit
        case .unknown, nil: Localization.predictionPositionsUnknown
        }
    }

    static func money(_ value: Decimal) -> String {
        PolymarketOrderFormatter.money(value)
    }

    static func signedMoney(_ value: Decimal) -> String {
        guard value != 0 else { return money(value) }

        let sign = value < 0 ? String.minusSign : String.plusSign

        return "\(sign) \(money(abs(value)))"
    }

    static func shares(_ value: Decimal) -> String {
        PolymarketOrderFormatter.shares(value)
    }
}

// MARK: - Constants

private extension PolymarketPositionDetailsView.Model {
    enum Constants {
        static let arrow = "→"

        static let quantityTileID = "quantity"
        static let priceChangeTileID = "priceChange"
        static let unrealizedTileID = "unrealized"
        static let realizedTileID = "realized"
    }
}

// MARK: - Hints

extension PolymarketPositionHintSheetView.Model {
    static let unrealizedPnl = Self(
        id: "unrealizedPnl",
        title: Localization.predictionPositionsUnrealizedPnl,
        message: Localization.predictionPositionsUnrealizedDescription
    )

    static let realizedPnl = Self(
        id: "realizedPnl",
        title: Localization.predictionPositionsRealizedPnl,
        message: Localization.predictionPositionsRealizedDescription
    )
}
