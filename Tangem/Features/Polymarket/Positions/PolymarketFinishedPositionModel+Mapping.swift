//
//  PolymarketFinishedPositionModel+Mapping.swift
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

extension PolymarketFinishedPositionSheetView.Model {
    static func make(closedPosition: PolymarketClosedPosition) -> Self {
        Self(
            id: closedPosition.id,
            title: Localization.predictionPositionsFinishedTitle,
            header: header(closedPosition: closedPosition),
            rows: rows(closedPosition: closedPosition)
        )
    }
}

// MARK: - Private implementation

private extension PolymarketFinishedPositionSheetView.Model {
    static func header(closedPosition: PolymarketClosedPosition) -> PolymarketPositionHeader.Model {
        PolymarketPositionHeader.Model(
            iconURL: closedPosition.iconURL,
            changeText: PolymarketPositionRow.Model.changeText(closedPosition: closedPosition),
            changeType: PriceChangeView.ChangeType(from: PolymarketOrderFormatter.displayedMoney(closedPosition.realizedPnl)),
            valueText: PolymarketOrderFormatter.money(abs(PolymarketOrderFormatter.displayedMoney(closedPosition.realizedPnl))),
            question: closedPosition.title.nilIfEmpty ?? Localization.predictionPositionsUnavailable,
            outcomeTitle: closedPosition.outcome,
            outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: closedPosition.outcomeIndex, name: closedPosition.outcome),
            payoutAmount: nil,
            status: PolymarketPositionRow.Model.status(for: closedPosition)
        )
    }

    static func rows(closedPosition: PolymarketClosedPosition) -> [PolymarketDetailsRowsBlock.Row] {
        var rows: [PolymarketDetailsRowsBlock.Row] = [
            .init(title: Localization.predictionPositionsOutcome, value: closedPosition.outcome),
        ]

        if let closedAt = closedPosition.closedAt {
            rows.append(.init(
                title: Localization.predictionPositionsClosureDate,
                value: PolymarketOrderResultFormatter.closedAt(closedAt)
            ))
        }

        return rows
    }
}
