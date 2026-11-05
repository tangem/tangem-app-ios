//
//  EarnCalculatorSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
@testable import Tangem

enum EarnCalculatorSnapshotScenario: String, SnapshotScenario {
    case card
    case cardTenYears
    case cardRTL
    case cardLargeText
    case withoutCard

    var canvases: [SnapshotCanvas] {
        switch self {
        case .cardLargeText: [.fixed(width: 390, height: 820)]
        case .card, .cardTenYears, .cardRTL, .withoutCard: [.fixed(width: 390, height: 600)]
        }
    }

    var layoutDirection: LayoutDirection {
        self == .cardRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .cardLargeText ? .xxxLarge : .large
    }

    @MainActor
    var body: some View {
        EarnCalculatorView(viewModel: viewModel, showsCard: self != .withoutCard)
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(DesignSystem.Color.bgPrimary)
    }

    @MainActor
    private var viewModel: EarnCalculatorViewModel {
        EarnCalculatorViewModel(
            input: self == .cardTenYears ? EarnCalculatorInput(initialBalance: 2500, monthlyTopUp: 500, horizon: .tenYears) : .default,
            incentiveApy: nil,
            projector: CompoundingEarnCalculatorProjector(apy: Decimal(449) / 10000, performanceFee: Decimal(15) / 100),
            currencyCode: "USD"
        )
    }
}
