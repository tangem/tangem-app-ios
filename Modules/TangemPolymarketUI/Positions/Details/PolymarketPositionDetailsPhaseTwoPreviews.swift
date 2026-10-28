//
//  PolymarketPositionDetailsPhaseTwoPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Previews

#Preview("Down") {
    PolymarketPositionDetailsPhaseTwoView(model: .down, onBack: {})
        .preferredColorScheme(.dark)
}

#Preview("Up") {
    PolymarketPositionDetailsPhaseTwoView(model: .up, onBack: {})
        .preferredColorScheme(.dark)
}

#Preview("Flat") {
    PolymarketPositionDetailsPhaseTwoView(model: .flat, onBack: {})
}

#Preview("Pending") {
    PolymarketPositionDetailsPhaseTwoView(model: .awaiting(.pendingResolution), onBack: {})
        .preferredColorScheme(.dark)
}

#Preview("Disputed") {
    PolymarketPositionDetailsPhaseTwoView(model: .awaiting(.disputed), onBack: {})
        .preferredColorScheme(.dark)
}

private extension PolymarketPositionDetailsPhaseTwoView.Model {
    static let down = make(
        currentValue: .init(caption: "Current value", valueText: "$4,000.00", changeText: "8.04% ($321.00)", changeDirection: .negative),
        change: .init(bought: .init(position: 0.5804, valueText: "58.04%"), now: .init(position: 0.5, valueText: "50%")),
        realizedProfit: .init(caption: "Realized Profit", valueText: "+ $321.81", onHintTap: {})
    )

    static let up = make(
        currentValue: .init(caption: "Current value", valueText: "$4,000.00", changeText: "8.04% ($321.00)", changeDirection: .positive),
        change: .init(bought: .init(position: 0.5, valueText: "50%"), now: .init(position: 0.5804, valueText: "58.04%")),
        realizedProfit: .init(caption: "Realized Profit", valueText: "+ $321.81", onHintTap: {})
    )

    static let flat = make(
        currentValue: .init(caption: "Current value", valueText: "$4,000.00", changeText: "0.00% ($0.00)", changeDirection: .neutral),
        change: .init(bought: .init(position: 0.5, valueText: "50%"), now: .init(position: 0.5, valueText: "50%")),
        realizedProfit: nil
    )

    static func awaiting(_ notice: PolymarketPositionNotice) -> Self {
        make(
            notice: notice,
            currentValue: up.currentValue,
            change: up.priceRange.change,
            realizedProfit: up.realizedProfit,
            isTradable: false
        )
    }

    static func make(
        notice: PolymarketPositionNotice? = nil,
        currentValue: PolymarketPositionDetailsPhaseTwoView.CurrentValue,
        change: PolymarketPositionPriceRangeView.Change,
        realizedProfit: PolymarketPositionDetailsPhaseTwoView.RealizedProfit?,
        isTradable: Bool = true
    ) -> Self {
        Self(
            summary: .init(
                iconURL: nil,
                question: "Will Uzbekistan win the 2026 FIFA World Cup?",
                outcomeTitle: "No",
                outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: 1)
            ),
            notice: notice,
            market: .init(title: "2026 World Cup Winner", iconURL: nil, onTap: {}),
            currentValue: currentValue,
            payout: .init(caption: "If you win", valueText: "$4,321.81", profitText: "+ $321.81 profit"),
            priceRange: .init(minText: "0%", maxText: "100%", change: change, onHintTap: {}),
            realizedProfit: realizedProfit,
            rows: [
                .init(title: "Notional of Position", value: "$800.00"),
                .init(title: "Qty of Tokens", value: "1,250.00"),
                .init(title: "Status", value: notice == nil ? "Open" : "Pending"),
                .init(title: "Resolution Date", value: "Dec 31, 2026"),
            ],
            secondaryAction: .init(title: "Cash Out", isEnabled: isTradable, perform: {}),
            primaryAction: .init(title: "Buy", isEnabled: isTradable, perform: {})
        )
    }
}
