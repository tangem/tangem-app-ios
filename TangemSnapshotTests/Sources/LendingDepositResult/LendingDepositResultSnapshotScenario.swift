//
//  LendingDepositResultSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
import TangemUI
@testable import Tangem

enum LendingDepositResultSnapshotScenario: String, SnapshotScenario {
    case deposited
    case largeText
    case rightToLeft

    var canvases: [SnapshotCanvas] { [.screen(.compact), .screen(.large)] }

    var dynamicTypeSize: DynamicTypeSize {
        self == .largeText ? .xxxLarge : .large
    }

    var layoutDirection: LayoutDirection {
        self == .rightToLeft ? .rightToLeft : .leftToRight
    }

    @MainActor
    var body: some View {
        LendingDepositResultContentView(
            state: LendingDepositResultContentView.StateModel(
                tokenIconInfo: TokenIconInfo(
                    name: "Ethereum",
                    blockchainIconAsset: nil,
                    imageURL: nil,
                    isCustom: false,
                    customTokenColor: nil
                ),
                amount: "0.5 ETH",
                currencySymbol: "ETH",
                sourceName: "Main account",
                currentApy: "5.5%"
            ),
            action: { _ in }
        )
        .environment(\._accessibilityReduceMotion, true)
    }
}
