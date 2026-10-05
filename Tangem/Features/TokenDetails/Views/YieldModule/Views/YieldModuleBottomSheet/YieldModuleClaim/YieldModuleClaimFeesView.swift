//
//  YieldModuleClaimFeesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct YieldModuleClaimFeesView: View {
    let networkFeeState: YieldFeeSectionState
    let serviceFeeState: YieldFeeSectionState
    let feeCurrencySymbol: String

    var body: some View {
        VStack(spacing: .zero) {
            feeRow(sectionState: networkFeeState, title: Localization.commonNetworkFeeTitle) {
                Badge(label: feeCurrencySymbol, accessibilityLabel: nil)
            }

            Separator(color: DesignSystem.Color.borderSecondary)
                .padding(.horizontal, Constants.rowHorizontalPadding)

            feeRow(sectionState: serviceFeeState, title: Localization.yieldModuleClaimServiceFeeTitle) {
                EmptyView()
            }
        }
    }

    private func feeRow(
        sectionState: YieldFeeSectionState,
        title: String,
        @ViewBuilder accessory: () -> some View
    ) -> some View {
        YieldFeeSection(
            sectionState: sectionState,
            leadingTitle: title,
            needsBackground: false,
            leadingTextAccessoryView: accessory
        )
        .padding(.horizontal, Constants.rowHorizontalPadding - Constants.feeSectionOwnInset)
        .padding(.vertical, Constants.rowVerticalPadding)
    }
}

// MARK: - Constants

private extension YieldModuleClaimFeesView {
    enum Constants {
        static let rowHorizontalPadding: CGFloat = 16
        static let rowVerticalPadding: CGFloat = 12
        static let feeSectionOwnInset: CGFloat = 4
    }
}
