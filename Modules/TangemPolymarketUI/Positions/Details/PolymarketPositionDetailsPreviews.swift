//
//  PolymarketPositionDetailsPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Previews

#Preview("Winning") {
    PolymarketPositionDetailsView(model: .winning, onBack: {})
}

#Preview("Losing") {
    PolymarketPositionDetailsView(model: .losing, onBack: {})
}

#Preview("Pending") {
    PolymarketPositionDetailsView(model: .pending, onBack: {})
}

#Preview("Disputed") {
    PolymarketPositionDetailsView(model: .disputed, onBack: {})
}

#Preview("Winning — Dark") {
    PolymarketPositionDetailsView(model: .winning, onBack: {})
        .preferredColorScheme(.dark)
}

private extension PolymarketPositionDetailsView.Model {
    static let winning = PolymarketPositionDetailsView.Model(
        header: .init(
            iconURL: nil,
            changeText: "10.94% ($40.50)",
            changeType: .positive,
            valueText: "$4,000.10",
            question: "Will Uzbekistan win the 2026 FIFA World Cup?",
            outcomeTitle: "Yes",
            outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: 0),
            payoutAmount: "$4,400.02"
        ),
        market: .init(
            id: "preview",
            title: "2026 World Cup Winner",
            category: .init(name: "Sport", icon: DesignSystem.Icons.Basketball.regular16),
            volumeText: "$6.3M",
            imageURL: nil,
            predictedText: nil,
            outcomes: []
        ),
        stats: [
            .init(id: "size", caption: "Qty of Tokens", value: "1,250.00"),
            .init(id: "price", caption: "Position Price Changes", value: "64¢ → 71¢"),
            .init(id: "unrealized", caption: "Unrealized PnL", value: "+ $87.50", tone: .positive, onHintTap: {}),
            .init(id: "realized", caption: "Realized Profit", value: "+ $420.00", tone: .positive, onHintTap: {}),
        ],
        rows: [
            .init(title: "Notional of Position", value: "$800.00"),
            .init(title: "Status", value: "Open"),
            .init(title: "Resolution Date", value: "22.03.2026"),
        ],
        openEventDetails: {},
        secondaryAction: .init(title: "Close", isEnabled: true, perform: {}),
        primaryAction: .init(title: "Buy", isEnabled: true, perform: {})
    )

    static let losing = PolymarketPositionDetailsView.Model(
        header: .init(
            iconURL: nil,
            changeText: "8.10% ($32.40)",
            changeType: .negative,
            valueText: "$367.60",
            question: "Will France not win the 2026 FIFA World Cup?",
            outcomeTitle: "No",
            outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: 1),
            payoutAmount: nil
        ),
        market: .init(
            id: "preview",
            title: "2026 World Cup Winner",
            category: .init(name: "Sport", icon: DesignSystem.Icons.Basketball.regular16),
            volumeText: "$6.3M",
            imageURL: nil,
            predictedText: nil,
            outcomes: []
        ),
        stats: [
            .init(id: "size", caption: "Qty of Tokens", value: "1,250.00"),
            .init(id: "price", caption: "Position Price Changes", value: "64¢ → 58¢"),
            .init(id: "unrealized", caption: "Unrealized PnL", value: "− $87.50", tone: .negative, onHintTap: {}),
            .init(id: "realized", caption: "Realized Profit", value: "− $420.00", tone: .negative, onHintTap: {}),
        ],
        rows: [
            .init(title: "Notional of Position", value: "$800.00"),
            .init(title: "Status", value: "Pending", subvalue: "Awaiting the final result"),
            .init(title: "Resolution Date", value: "22.03.2026", hasHint: true),
        ],
        openEventDetails: {},
        secondaryAction: .init(title: "Close", isEnabled: false, perform: {}),
        primaryAction: .init(title: "Buy", isEnabled: false, perform: {})
    )
}

private extension PolymarketPositionDetailsView.Model {
    static let pending = winning.awaiting(.pendingResolution, status: "Pending")

    static let disputed = winning.awaiting(.disputed, status: "Disputed")

    func awaiting(_ notice: PolymarketPositionNotice, status: String) -> PolymarketPositionDetailsView.Model {
        PolymarketPositionDetailsView.Model(
            header: header,
            market: market,
            stats: stats,
            rows: rows.map { $0.title == "Status" ? .init(title: $0.title, value: status) : $0 },
            notice: notice,
            openEventDetails: {},
            secondaryAction: secondaryAction.map { .init(title: $0.title, isEnabled: false, perform: $0.perform) },
            primaryAction: primaryAction.map { .init(title: $0.title, isEnabled: false, perform: $0.perform) }
        )
    }
}
