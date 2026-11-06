//
//  LendingPositionSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
@testable import Tangem

enum LendingPositionSnapshotScenario: String, SnapshotScenario {
    case loaded
    case loadedLargeText
    case loadedRightToLeft
    case chartError
    case positionUnavailable

    var canvases: [SnapshotCanvas] {
        switch self {
        case .loaded: [.screen(.compact), .screen(.regular)]
        case .loadedLargeText, .loadedRightToLeft, .chartError, .positionUnavailable: [.screen(.regular)]
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .loadedLargeText ? .xxxLarge : .large
    }

    var layoutDirection: LayoutDirection {
        self == .loadedRightToLeft ? .rightToLeft : .leftToRight
    }

    @MainActor
    var body: some View {
        NavigationStack {
            LendingPositionContentView(
                state: state,
                calculator: EarnCalculatorViewModel(
                    input: .default,
                    incentiveApy: nil,
                    projector: CompoundingEarnCalculatorProjector(apy: Decimal(449) / 10000, performanceFee: Decimal(15) / 100),
                    currencyCode: "USD"
                ),
                action: { _ in }
            )
        }
        .environment(\._accessibilityReduceMotion, true)
    }

    private var state: LendingPositionContentView.StateModel {
        let isUnavailable = self == .positionUnavailable

        return LendingPositionContentView.StateModel(
            balance: isUnavailable ? .init(fiat: "–", crypto: "–") : .init(fiat: "$5,200.52", crypto: "ETH 1.482"),
            availableBalance: isUnavailable ? "–" : "ETH 1.482",
            currentApy: "4.49%",
            isApyKnown: true,
            chart: self == .chartError ? .error(action: {}) : .loaded(Self.chart),
            period: .sixMonths,
            canWithdraw: !isUnavailable,
            details: .preview,
            totalBalanceInfo: .init(title: "Total balance", content: .text("")),
            availableBalanceInfo: .init(title: "Available balance", content: .text(""))
        )
    }

    private static let chart = YieldChartData(
        buckets: [4.1, 4.4, 4.9, 5.6, 5.2, 4.8, 5.0, 5.4, 5.9, 6.2, 5.7, 5.1, 4.6, 4.9, 5.3, 5.6, 5.0, 4.7, 4.4, 4.9, 5.2, 5.5, 5.8, 5.1, 4.8, 4.5, 4.9, 5.2, 4.49],
        averageApy: 5.12,
        maxApy: 6.2,
        xTicks: [4: "Jun", 9: "Jul", 14: "Aug", 19: "Sep", 24: "Oct"]
    )
}
