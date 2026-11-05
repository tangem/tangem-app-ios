//
//  EarnYieldPickerSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSnapshotTestSupport
@testable import Tangem

enum EarnYieldPickerSnapshotScenario: String, SnapshotScenario {
    case lendingOnAave
    case pooledStaking
    case addFunds
    case lendingOnAaveRTL
    case lendingOnAaveLargeText

    var canvases: [SnapshotCanvas] {
        switch self {
        case .lendingOnAave: [.screen(.compact), .screen(.regular)]
        case .pooledStaking, .addFunds, .lendingOnAaveRTL, .lendingOnAaveLargeText: [.screen(.regular)]
        }
    }

    var layoutDirection: LayoutDirection {
        self == .lendingOnAaveRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .lendingOnAaveLargeText ? .xxxLarge : .large
    }

    @MainActor
    var body: some View {
        NavigationStack {
            if let viewModel = EarnYieldPickerViewModel(
                products: [.pooledStakingPreview, .lendingOnAavePreview],
                selectedProductID: self == .pooledStaking ? .pooledStaking : .lendingOnAave,
                balanceProvider: NFTSendFixedBalanceProvider(
                    tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                    fixedValue: self == .addFunds ? 0 : 1
                ),
                currencyCode: "USD",
                videoProvider: NoVideoProvider(),
                coordinator: nil
            ) {
                EarnYieldPickerView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Stubs

private struct NoVideoProvider: LoopingVideoBackgroundProvider {
    func videoURL() -> URL? { nil }
    func handleMissingAsset() {}
}
