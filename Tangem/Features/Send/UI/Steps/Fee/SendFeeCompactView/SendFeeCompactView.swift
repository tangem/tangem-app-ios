//
//  SendFeeCompactView.swift
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

struct SendFeeCompactView: View {
    @ObservedObject var viewModel: SendFeeCompactViewModel

    var body: some View {
        BaseOneLineRow(
            icon: Assets.Glyphs.feeNew,
            title: Localization.commonNetworkFeeTitle,
            secondLeadingView: {
                InfoButtonView(size: .medium, tooltipText: .attributed(text: viewModel.infoButtonString))
            },
            trailingView: {
                LoadableTextView(
                    state: viewModel.selectedFeeComponents,
                    font: Fonts.Regular.body,
                    textColor: Colors.Text.tertiary,
                    loaderSize: CGSize(width: 70, height: 15)
                )
                .accessibilityIdentifier(SendAccessibilityIdentifiers.networkFeeAmount)
            }
        )
        .shouldShowTrailingIcon(viewModel.canEditFee)
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 11, horizontalPadding: 14)
    }
}
