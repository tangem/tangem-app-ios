//
//  LendingDepositResultContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct LendingDepositResultContentView: View {
    let state: StateModel
    let action: (Action) -> Void

    @ScaledMetric private var iconScale: CGFloat = 1

    var body: some View {
        StatusScreen(
            // [REDACTED_TODO_COMMENT]
            title: "Deposited \(state.amount)",
            description: "Your \(state.currencySymbol) in \(state.sourceName) is now earning in Aave",
            actionTitle: Localization.yieldModuleClaimGoToYieldButton,
            action: { action(.toYield) }
        )
        .appearance(.success)
        .secondaryAction(title: Localization.commonGoToToken) { action(.toToken) }
        .footerAxis(.horizontal)
        .assetSlot { icons }
        .headerAccessory { apyBadge }
    }
}

// MARK: - Subviews

private extension LendingDepositResultContentView {
    var icons: some View {
        HStack(spacing: -Constants.iconOverlap) {
            TokenIconV2(tokenIconInfo: state.tokenIconInfo, size: .size56)
                .zIndex(1)

            Assets.YieldModule.yieldModuleAaveLogo.image
                .resizable()
                .frame(width: aaveIconSide, height: aaveIconSide)
                .clipShape(Circle())
        }
        .accessibilityHidden(true)
    }

    var aaveIconSide: CGFloat {
        Constants.iconSide * min(max(iconScale, Constants.minIconScale), Constants.maxIconScale)
    }

    var apyBadge: some View {
        // [REDACTED_TODO_COMMENT]
        Badge(label: "Current \(state.currentApy) APY", accessibilityLabel: nil)
            .appearance(.success)
            .slotStart(DesignSystem.Icons.Dot.filled12)
    }
}

// MARK: - StateModel

extension LendingDepositResultContentView {
    struct StateModel {
        let tokenIconInfo: TokenIconInfo
        let amount: String
        let currencySymbol: String
        let sourceName: String
        let currentApy: String
    }

    enum Action {
        case toToken
        case toYield
    }
}

// MARK: - Constants

private extension LendingDepositResultContentView {
    enum Constants {
        static let iconSide: CGFloat = 56
        static let minIconScale: CGFloat = 1
        static let maxIconScale: CGFloat = 1.5
        static let iconOverlap: CGFloat = 8
    }
}
