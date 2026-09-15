//
//  PolymarketPositionRowModel+Mapping.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

extension PolymarketPositionRow.Model {
    static func make(position: PolymarketPosition) -> Self {
        Self(
            id: position.id,
            question: question(position: position),
            imageURL: position.iconURL,
            outcomeTitle: position.outcome,
            outcomeStyle: PolymarketOutcomeStyle(binaryOutcomeName: position.outcome),
            change: PolymarketPositionRow.Change(
                text: changeText(position: position),
                type: PriceChangeView.ChangeType(from: position.cashPnl)
            ),
            trailing: trailing(position: position),
            glowRing: glowRing(position: position)
        )
    }
}

// MARK: - Private implementation

private extension PolymarketPositionRow.Model {
    static let percentFormatter = PercentFormatter()

    static func question(position: PolymarketPosition) -> String {
        position.title.nilIfEmpty
            ?? position.eventTitle?.nilIfEmpty
            ?? Localization.predictionPositionsUnavailable
    }

    static func changeText(position: PolymarketPosition) -> String {
        let amount = PolymarketOrderFormatter.money(abs(position.cashPnl))
        let percent = percentFormatter.format(position.pnlRatio, option: .priceChange)

        return "\(amount) (\(percent))"
    }

    static func trailing(position: PolymarketPosition) -> PolymarketPositionRow.Trailing {
        if let settlement = position.settlement {
            return .status(settled(settlement, position: position))
        }

        if let notice = notice(for: position.resolutionStatus) {
            return .status(notice)
        }

        return .value(PolymarketOrderFormatter.money(position.currentValue))
    }

    static func settled(
        _ settlement: PolymarketPositionSettlement,
        position: PolymarketPosition
    ) -> PolymarketPositionRow.Status {
        let amount = PolymarketOrderFormatter.money(position.currentValue)
        let lost = PolymarketOrderFormatter.money(abs(position.realizedPnl + position.cashPnl))

        switch settlement {
        case .won:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsWon, amount),
                variant: position.isRedeemable ? .solid : .tinted,
                appearance: .success,
                icon: DesignSystem.Icons.Success.regular16
            )
        case .lost:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsLost, lost),
                variant: .tinted,
                appearance: .error,
                icon: DesignSystem.Icons.HeartBroken.regular16
            )
        case .split:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsSplit, amount),
                variant: .tinted,
                appearance: .neutral,
                icon: DesignSystem.Icons.ArrowSplitTop.regular16
            )
        case .unknown:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsUnknown, amount),
                variant: .tinted,
                appearance: .neutral,
                icon: nil
            )
        }
    }

    static func notice(for status: PolymarketResolutionStatus) -> PolymarketPositionRow.Status? {
        let text: String

        switch status {
        case .disputed: text = Localization.predictionPositionsDisputed
        case .pendingResolution, .proposed: text = Localization.predictionPositionsPending
        case .open, .resolved, .unknown: return nil
        }

        return PolymarketPositionRow.Status(text: text, variant: .tinted, appearance: .warning, icon: nil)
    }

    static func glowRing(position: PolymarketPosition) -> GlowRingAppearance? {
        guard position.settlement != nil else { return nil }

        return position.realizedPnl + position.cashPnl < 0 ? .error : .info
    }
}

// MARK: - Closed positions

extension PolymarketPositionRow.Model {
    static func make(closedPosition: PolymarketClosedPosition) -> Self {
        Self(
            id: closedPosition.id,
            question: closedPosition.title.nilIfEmpty ?? Localization.predictionPositionsUnavailable,
            imageURL: closedPosition.iconURL,
            outcomeTitle: closedPosition.outcome,
            outcomeStyle: PolymarketOutcomeStyle(binaryOutcomeName: closedPosition.outcome),
            change: PolymarketPositionRow.Change(
                text: changeText(closedPosition: closedPosition),
                type: PriceChangeView.ChangeType(from: closedPosition.realizedPnl)
            ),
            trailing: .status(status(for: closedPosition)),
            glowRing: nil
        )
    }

    static func changeText(closedPosition: PolymarketClosedPosition) -> String {
        let amount = PolymarketOrderFormatter.money(abs(closedPosition.realizedPnl))

        guard closedPosition.totalBought > 0 else { return amount }

        let percent = percentFormatter.format(
            closedPosition.realizedPnl / closedPosition.totalBought,
            option: .priceChange
        )

        return "\(amount) (\(percent))"
    }

    static func status(for closedPosition: PolymarketClosedPosition) -> PolymarketPositionRow.Status {
        let amount = PolymarketOrderFormatter.money(closedPosition.totalBought + closedPosition.realizedPnl)
        let lost = PolymarketOrderFormatter.money(abs(closedPosition.realizedPnl))

        switch closedPosition.status {
        case .won:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsWon, amount),
                variant: .tinted,
                appearance: .success,
                icon: DesignSystem.Icons.Success.regular16
            )
        case .lost:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsLost, lost),
                variant: .tinted,
                appearance: .error,
                icon: DesignSystem.Icons.HeartBroken.regular16
            )
        case .split:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsSplit, amount),
                variant: .tinted,
                appearance: .neutral,
                icon: DesignSystem.Icons.ArrowSplitTop.regular16
            )
        case .closed:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsClosed, amount),
                variant: .tinted,
                appearance: closedPosition.realizedPnl < 0 ? .error : .success,
                icon: nil
            )
        case .unknown:
            return PolymarketPositionRow.Status(
                text: Localization.predictionPositionsResultAmount(Localization.predictionPositionsUnknown, amount),
                variant: .tinted,
                appearance: .neutral,
                icon: nil
            )
        }
    }
}
