//
//  EthYieldSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
@testable import Tangem

enum EthYieldSnapshotScenario: String, SnapshotScenario {
    case yieldEnabledCard
    case yieldEnabledCardLargeText
    case yieldEnabledCardRightToLeft
    case sheetLendingActive
    case sheetStakingActive
    case sheetBothActive
    case sheetLargeText
    case sheetRightToLeft

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .yieldEnabledCardLargeText, .sheetLargeText: .xxxLarge
        default: .large
        }
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .yieldEnabledCardRightToLeft, .sheetRightToLeft: .rightToLeft
        default: .leftToRight
        }
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        switch self {
        case .yieldEnabledCard, .yieldEnabledCardLargeText, .yieldEnabledCardRightToLeft:
            TokenDetailsStakingView(state: .yieldEnabled(item: .init(
                title: "Yield enabled",
                balance: "1.3254 ETH",
                activeCount: "1 active",
                action: {}
            )))
            .frame(width: Self.width)
            .environment(\._accessibilityReduceMotion, true)
        case .sheetLendingActive, .sheetLargeText, .sheetRightToLeft:
            sheet(active: [Self.lendingActive], inactive: [Self.stakingInactive])
        case .sheetStakingActive:
            sheet(active: [Self.stakingActive], inactive: [Self.lendingInactive])
        case .sheetBothActive:
            sheet(active: [Self.lendingActive, Self.stakingActive], inactive: [])
        }
    }
}

// MARK: - Samples

private extension EthYieldSnapshotScenario {
    static let width: CGFloat = 370

    static let lendingActive = EthYieldSheetViewModel.RowItem(
        id: .lendingOnAave,
        name: "Lending on Aave",
        icon: .logo(Assets.YieldModule.yieldModuleAaveLogo),
        content: .active(rate: "1.6% net APY", cryptoBalance: "0.5031 ETH", fiatBalance: "$2,012.40"),
        action: {}
    )

    static let stakingActive = EthYieldSheetViewModel.RowItem(
        id: .pooledStaking,
        name: "Pooled staking",
        icon: .illustration(DesignSystem.Icons.accountStaking),
        content: .active(rate: "3.1% APY", cryptoBalance: "0.8223 ETH", fiatBalance: "$3,188.12"),
        action: {}
    )

    static let stakingInactive = EthYieldSheetViewModel.RowItem(
        id: .pooledStaking,
        name: "Pooled staking",
        icon: .illustration(DesignSystem.Icons.accountStaking),
        content: .inactive(rate: "3.1% APY", risk: "Low risk"),
        action: {}
    )

    static let lendingInactive = EthYieldSheetViewModel.RowItem(
        id: .lendingOnAave,
        name: "Lending on Aave",
        icon: .logo(Assets.YieldModule.yieldModuleAaveLogo),
        content: .inactive(rate: "2.4% APY", risk: "Low risk"),
        action: {}
    )

    func sheet(active: [EthYieldSheetViewModel.RowItem], inactive: [EthYieldSheetViewModel.RowItem]) -> some View {
        EthYieldSheetView(viewModel: EthYieldSheetViewModel(activeRows: active, inactiveRows: inactive))
            .frame(width: Self.width)
    }
}
