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
        openEventDetails: @escaping () -> Void,
        onClosePosition: @escaping () -> Void,
        onBuy: @escaping () -> Void,
        onMarketUnavailable: @escaping () -> Void,
        onHint: @escaping (PolymarketPositionHintSheetView.Model) -> Void,
        loadingSide: PolymarketOrderSide?
    ) -> Self {
        let availability = TradeAvailability(position: position)
        let isOrderLoading = loadingSide != nil

        return Self(
            header: header(position: position),
            market: market(position: position),
            stats: stats(position: position, onHint: onHint),
            rows: rows(position: position),
            notice: notice(position: position),
            openEventDetails: openEventDetails,
            secondaryAction: action(
                title: Localization.predictionCashOut,
                availability: availability,
                isOrderLoading: isOrderLoading,
                isLoading: loadingSide == .sell,
                perform: onClosePosition,
                onMarketUnavailable: onMarketUnavailable
            ),
            primaryAction: action(
                title: Localization.commonBuy,
                availability: availability,
                isOrderLoading: isOrderLoading,
                isLoading: loadingSide == .buy,
                perform: onBuy,
                onMarketUnavailable: onMarketUnavailable
            )
        )
    }
}

// MARK: - Blocks

private extension PolymarketPositionDetailsView.Model {
    static func header(position: PolymarketPosition) -> PolymarketPositionHeader.Model {
        PolymarketPositionHeader.Model(
            iconURL: position.iconURL,
            change: PolymarketPositionRow.Change(
                text: changeText(position: position),
                type: PriceChangeView.ChangeType(from: displayedMoney(position.cashPnl))
            ),
            valueText: money(position.currentValue),
            question: question(position: position),
            outcomeTitle: position.outcome,
            outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: position.outcomeIndex, name: position.outcome),
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
                tone: PolymarketValueTone(pnl: displayedMoney(position.cashPnl)),
                onHintTap: { onHint(.unrealizedPnl) }
            ),
            .init(
                id: Constants.realizedTileID,
                caption: Localization.predictionPositionsRealizedPnl,
                value: signedMoney(position.realizedPnl),
                tone: PolymarketValueTone(pnl: displayedMoney(position.realizedPnl)),
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

    static func action(
        title: String,
        availability: TradeAvailability,
        isOrderLoading: Bool,
        isLoading: Bool,
        perform: @escaping () -> Void,
        onMarketUnavailable: @escaping () -> Void
    ) -> PolymarketPositionDetailsView.Action {
        switch availability {
        case .tradable:
            PolymarketPositionDetailsView.Action(title: title, isEnabled: !isOrderLoading, isLoading: isLoading, perform: perform)
        case .marketUnavailable:
            PolymarketPositionDetailsView.Action(title: title, isEnabled: !isOrderLoading, perform: onMarketUnavailable)
        case .locked:
            PolymarketPositionDetailsView.Action(title: title, isEnabled: false, perform: perform)
        }
    }
}

// MARK: - Trade availability

private extension PolymarketPositionDetailsView.Model {
    enum TradeAvailability {
        case tradable
        case marketUnavailable
        case locked

        init(position: PolymarketPosition) {
            if position.resolutionStatus == .open {
                let canTrade = position.isAcceptingOrders && position.marketId != nil && position.eventId != nil
                self = canTrade ? .tradable : .locked
            } else {
                self = PolymarketPositionDetailsView.Model.notice(position: position) == nil ? .marketUnavailable : .locked
            }
        }
    }
}

// MARK: - Values

private extension PolymarketPositionDetailsView.Model {
    static let percentFormatter = PercentFormatter()

    static func question(position: PolymarketPosition) -> String {
        position.question ?? Localization.predictionPositionsUnavailable
    }

    static func marketTitle(position: PolymarketPosition) -> String {
        position.eventTitle?.nilIfEmpty
            ?? position.title.nilIfEmpty
            ?? Localization.predictionPositionsUnavailable
    }

    static func changeText(position: PolymarketPosition) -> String {
        let percent = percentFormatter.format(position.pnlRatio, option: .priceChange)
        let amount = money(abs(displayedMoney(position.cashPnl)))

        return "\(percent) (\(amount))"
    }

    static func payoutAmount(position: PolymarketPosition) -> String? {
        guard position.settlement == nil else { return nil }

        return money(position.size)
    }

    static func priceChange(position: PolymarketPosition) -> String {
        let from = PolymarketPriceFormatter.centsText(position.avgPrice)
        let to = PolymarketPriceFormatter.centsText(position.curPrice, isResolved: position.settlement?.isResolved == true)

        return "\(from) \(Constants.arrow) \(to)"
    }

    static func statusText(position: PolymarketPosition) -> String {
        switch position.resolutionStatus {
        case .open: Localization.predictionPositionsOpen
        case .pendingResolution, .proposed: Localization.predictionPositionsPending
        case .disputed: Localization.predictionPositionsDisputed
        case .resolved: settlementText(position: position)
        case .unknown: Localization.predictionPositionsPending
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
        PolymarketOrderFormatter.signedMoney(value)
    }

    static func displayedMoney(_ value: Decimal) -> Decimal {
        PolymarketOrderFormatter.displayedMoney(value)
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

// MARK: - Phase two

extension PolymarketPositionDetailsPhaseTwoView.Model {
    private typealias Values = PolymarketPositionDetailsView.Model

    static func make(
        position: PolymarketPosition,
        openEventDetails: @escaping () -> Void,
        onClosePosition: @escaping () -> Void,
        onBuy: @escaping () -> Void,
        onMarketUnavailable: @escaping () -> Void,
        onHint: @escaping (PolymarketPositionHintSheetView.Model) -> Void,
        loadingSide: PolymarketOrderSide?
    ) -> Self {
        let availability = Values.TradeAvailability(position: position)
        let isOrderLoading = loadingSide != nil

        return Self(
            summary: .init(
                iconURL: position.iconURL,
                question: Values.question(position: position),
                outcomeTitle: position.outcome,
                outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: position.outcomeIndex, name: position.outcome)
            ),
            notice: Values.notice(position: position),
            market: .init(
                title: Values.marketTitle(position: position),
                iconURL: position.iconURL,
                onTap: openEventDetails
            ),
            currentValue: currentValue(position: position),
            payout: payout(position: position),
            priceRange: priceRange(position: position, onHintTap: { onHint(.unrealizedPnl) }),
            realizedProfit: realizedProfit(position: position, onHintTap: { onHint(.realizedPnl) }),
            rows: rows(position: position),
            secondaryAction: Values.action(
                title: Localization.predictionCashOut,
                availability: availability,
                isOrderLoading: isOrderLoading,
                isLoading: loadingSide == .sell,
                perform: onClosePosition,
                onMarketUnavailable: onMarketUnavailable
            ),
            primaryAction: Values.action(
                title: Localization.commonBuy,
                availability: availability,
                isOrderLoading: isOrderLoading,
                isLoading: loadingSide == .buy,
                perform: onBuy,
                onMarketUnavailable: onMarketUnavailable
            )
        )
    }
}

private extension PolymarketPositionDetailsPhaseTwoView.Model {
    static func currentValue(position: PolymarketPosition) -> PolymarketPositionDetailsPhaseTwoView.CurrentValue {
        PolymarketPositionDetailsPhaseTwoView.CurrentValue(
            caption: "Current value",
            valueText: Values.money(position.currentValue),
            changeText: Values.changeText(position: position),
            changeDirection: direction(of: Values.displayedMoney(position.cashPnl))
        )
    }

    static func payout(position: PolymarketPosition) -> PolymarketPositionDetailsPhaseTwoView.Payout? {
        guard let payoutAmount = Values.payoutAmount(position: position) else { return nil }

        let profit = Values.signedMoney(position.size - position.initialValue)

        return PolymarketPositionDetailsPhaseTwoView.Payout(
            caption: "If you win",
            valueText: payoutAmount,
            profitText: "\(profit) profit"
        )
    }

    static func priceRange(position: PolymarketPosition, onHintTap: @escaping () -> Void) -> PolymarketPositionPriceRangeView.Model {
        PolymarketPositionPriceRangeView.Model(
            minText: Values.percentFormatter.format(Constants.minPrice, option: .predictionPrice),
            maxText: Values.percentFormatter.format(Constants.maxPrice, option: .predictionPrice),
            change: .init(
                bought: mark(displayedPrice(position.avgPrice)),
                now: mark(displayedPrice(position.curPrice))
            ),
            onHintTap: onHintTap
        )
    }

    static func realizedProfit(
        position: PolymarketPosition,
        onHintTap: @escaping () -> Void
    ) -> PolymarketPositionDetailsPhaseTwoView.RealizedProfit? {
        guard Values.displayedMoney(position.realizedPnl) != 0 else { return nil }

        return PolymarketPositionDetailsPhaseTwoView.RealizedProfit(
            caption: "Realized Profit",
            valueText: Values.signedMoney(position.realizedPnl),
            onHintTap: onHintTap
        )
    }

    static func rows(position: PolymarketPosition) -> [PolymarketDetailsRowsBlock.Row] {
        var rows: [PolymarketDetailsRowsBlock.Row] = [
            .init(title: "Notional of Position", value: Values.money(position.initialValue)),
            .init(title: Localization.predictionPositionsQuantity, value: Values.shares(position.size)),
            .init(title: Localization.predictionPositionsStatus, value: Values.statusText(position: position)),
        ]

        if let endDate = position.endDate {
            rows.append(.init(
                title: Localization.predictionDetailsResolutionDate,
                value: PolymarketOrderResultFormatter.resolutionDay(endDate)
            ))
        }

        return rows
    }

    static func displayedPrice(_ price: Decimal) -> Decimal {
        clamp(price, min: Constants.minPrice, max: Constants.maxPrice)
            .rounded(scale: Constants.displayedPriceScale, roundingMode: .plain)
    }

    static func mark(_ price: Decimal) -> PolymarketPositionPriceRangeView.Mark {
        PolymarketPositionPriceRangeView.Mark(
            position: price.doubleValue,
            valueText: Values.percentFormatter.format(price, option: .predictionPrice)
        )
    }

    static func direction(of value: Decimal) -> UtilPriceChange.Direction {
        switch PriceChangeView.ChangeType(from: value) {
        case .positive:
            .positive
        case .neutral:
            .neutral
        case .negative:
            .negative
        }
    }

    enum Constants {
        static let minPrice: Decimal = 0
        static let maxPrice: Decimal = 1
        static let displayedPriceScale = 4
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
