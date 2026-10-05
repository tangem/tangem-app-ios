//
//  YieldModuleClaimSuccessView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct YieldModuleClaimSuccessView: View {
    let data: YieldModuleClaimSuccessViewData
    let networkFeeState: YieldFeeSectionState
    let serviceFeeState: YieldFeeSectionState
    let feeCurrencySymbol: String
    let toTokenAction: () -> Void
    let toYieldAction: () -> Void

    // MARK: - View Body

    var body: some View {
        StatusScreen(
            title: [Localization.yieldModuleClaimInProgressTitle, data.total].joined(separator: "\n"),
            description: Localization.yieldModuleClaimInProgressDescription,
            actionTitle: Localization.yieldModuleClaimGoToYieldButton,
            action: toYieldAction
        )
        .appearance(.info)
        .secondaryAction(title: Localization.commonGoToToken, action: toTokenAction)
        .footerAxis(.horizontal)
        .assetSlot {
            StatusIcon(.checkmark)
                .tint(DesignSystem.Color.iconStatusInfo)
                .startDelay(Constants.iconStartDelay)
        }
        .details {
            YieldModuleClaimFeesView(
                networkFeeState: networkFeeState,
                serviceFeeState: serviceFeeState,
                feeCurrencySymbol: feeCurrencySymbol
            )
        }
    }
}

// MARK: - Constants

private extension YieldModuleClaimSuccessView {
    enum Constants {
        /// Matches the delay `StatusScreen` gives the icon it draws itself, which a filled asset slot replaces.
        static let iconStartDelay: TimeInterval = 0.3
    }
}

// MARK: - Previews

#Preview {
    YieldModuleClaimSuccessView(
        data: YieldModuleClaimSuccessViewData(total: "$45.50"),
        networkFeeState: YieldFeeSectionState(feeState: .loaded(text: "$1.40")),
        serviceFeeState: YieldFeeSectionState(feeState: .loaded(text: "(15%) $1.40")),
        feeCurrencySymbol: "USDT",
        toTokenAction: {},
        toYieldAction: {}
    )
}
