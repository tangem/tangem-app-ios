//
//  FeeCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct FeeCompactView: View {
    @ObservedObject var viewModel: FeeCompactViewModel
    let tapAction: (() -> Void)?

    var body: some View {
        if let tapAction, viewModel.canEditFee {
            Button(action: tapAction) { content }
        } else {
            content
        }
    }

    private var content: some View {
        BaseOneLineRow(
            icon: Assets.Glyphs.feeNew,
            title: Localization.commonNetworkFeeTitle,
            secondLeadingView: {
                InfoButtonView(size: .medium, tooltipText: .attributed(text: viewModel.infoButtonString))
            },
            trailingView: {
                HStack(alignment: .center, spacing: 4) {
                    tokenItemBadge

                    LoadableTextView(
                        state: viewModel.selectedFeeComponents,
                        font: Fonts.Regular.body,
                        textColor: Colors.Text.tertiary,
                        loaderSize: CGSize(width: 40, height: 15)
                    )
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.networkFeeAmount)
                }
            }
        )
        .shouldShowTrailingIcon(viewModel.canEditFee)
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 11, horizontalPadding: 14)
    }

    @ViewBuilder
    private var tokenItemBadge: some View {
        if let currencySymbol = viewModel.selectedFeeTokenCurrencySymbol {
            Text(currencySymbol)
                .style(Fonts.Bold.caption2, color: Colors.Text.secondary)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(Colors.Background.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
