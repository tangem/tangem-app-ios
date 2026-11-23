//
//  EarnGetTokenSheetSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
@testable import Tangem

enum EarnGetTokenSheetSnapshotScenario: String, SnapshotScenario {
    case allOptions
    case buyUnavailable
    case largeText
    case rightToLeft

    var dynamicTypeSize: DynamicTypeSize {
        self == .largeText ? .xxxLarge : .large
    }

    var layoutDirection: LayoutDirection {
        self == .rightToLeft ? .rightToLeft : .leftToRight
    }

    @MainActor
    var body: some View {
        EarnGetTokenSheetView(viewModel: .make(
            tokenSymbol: "ETH",
            options: [
                .init(type: .receive, isAvailable: true),
                .init(type: .exchange, isAvailable: true),
                .init(type: .buy, isAvailable: self != .buyUnavailable),
            ],
            onSelect: { _ in }
        ))
        .frame(width: 370)
    }
}
