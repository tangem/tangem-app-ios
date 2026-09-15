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
            // [REDACTED_TODO_COMMENT]
            title: "Finished position",
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
            changeType: PriceChangeView.ChangeType(from: closedPosition.realizedPnl),
            valueText: PolymarketOrderFormatter.money(closedPosition.totalBought + closedPosition.realizedPnl),
            question: closedPosition.title.nilIfEmpty ?? Localization.predictionPositionsUnavailable,
            outcomeTitle: closedPosition.outcome,
            outcomeStyle: PolymarketOutcomeStyle(binaryOutcomeName: closedPosition.outcome),
            payoutAmount: nil,
            status: PolymarketPositionRow.Model.status(for: closedPosition)
        )
    }

    static func rows(closedPosition: PolymarketClosedPosition) -> [PolymarketDetailsRowsBlock.Row] {
        var rows: [PolymarketDetailsRowsBlock.Row] = [
            // [REDACTED_TODO_COMMENT]
            .init(title: "Outcome", value: closedPosition.outcome),
        ]

        if let closedAt = closedPosition.closedAt {
            // [REDACTED_TODO_COMMENT]
            rows.append(.init(title: "Closure Date", value: PolymarketOrderResultFormatter.closedAt(closedAt)))
        }

        return rows
    }
}
