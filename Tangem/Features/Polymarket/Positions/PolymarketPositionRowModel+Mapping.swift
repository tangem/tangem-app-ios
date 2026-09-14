//
//  PolymarketPositionRowModel+Mapping.swift
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

extension PolymarketPositionRow.Model {
    static func make(position: PolymarketPosition) -> Self {
        Self(
            id: position.id,
            question: question(position: position),
            imageURL: position.iconURL,
            outcomeTitle: position.outcome,
            outcomeStyle: PolymarketOutcomeStyle(binaryOutcomeName: position.outcome),
            changeText: changeText(position: position),
            changeType: PriceChangeView.ChangeType(from: position.cashPnl),
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
        guard let settlement = position.settlement else {
            return .value(PolymarketOrderFormatter.money(position.currentValue))
        }

        let outcome = PolymarketOrderFormatter.money(position.realizedPnl + position.cashPnl)

        let label = switch settlement {
        case .won: Localization.predictionPositionsWon
        case .lost: Localization.predictionPositionsLost
        case .split: Localization.predictionPositionsSplit
        case .unknown: Localization.predictionPositionsUnknown
        }

        return .settled(Localization.predictionPositionsResultAmount(label, outcome))
    }

    static func glowRing(position: PolymarketPosition) -> GlowRingAppearance? {
        guard position.isRedeemable else { return nil }

        return position.cashPnl < 0 ? .error : .info
    }
}
