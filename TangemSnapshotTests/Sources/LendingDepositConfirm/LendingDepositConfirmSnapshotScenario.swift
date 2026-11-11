//
//  LendingDepositConfirmSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
import TangemUI
@testable import Tangem

enum LendingDepositConfirmSnapshotScenario: String, SnapshotScenario {
    case cardTap
    case holdToConfirm
    case feeUnavailable
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
        NavigationStack {
            LendingDepositConfirmContentView(state: state, action: { _ in })
        }
    }
}

// MARK: - Content

private extension LendingDepositConfirmSnapshotScenario {
    var state: LendingDepositConfirmContentView.StateModel {
        LendingDepositConfirmContentView.StateModel(
            tokenIconInfo: TokenIconInfo(
                name: "Ethereum",
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: nil
            ),
            fiatAmount: "$800",
            cryptoAmount: "0.5 ETH",
            currentApy: "5.5%",
            performanceFee: "15%",
            projectedEarnings: "~$37/year",
            fee: self == .feeUnavailable ? .unavailable : .loaded(symbol: "ETH", value: "$1.40"),
            canChangeFeeSpeed: self != .feeUnavailable,
            signingActionButtonType: self == .holdToConfirm ? .holdToConfirm : .requiredNFCInteraction,
            isDepositEnabled: self != .feeUnavailable,
            isDepositing: false
        )
    }
}
