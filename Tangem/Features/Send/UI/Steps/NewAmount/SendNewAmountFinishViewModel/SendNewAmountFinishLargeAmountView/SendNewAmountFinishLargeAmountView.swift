//
//  SendNewAmountFinishLargeAmountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI
import TangemAssets
import TangemLocalization

struct SendNewAmountFinishLargeAmountView: View {
    @ObservedObject var viewModel: SendNewAmountFinishLargeAmountViewModel

    var body: some View {
        VStack(spacing: 16) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 36, height: 36),
                // Kingfisher shows a grey background even if there has a cached image
                forceKingfisher: false
            )

            VStack(alignment: .center, spacing: 4) {
                SendDecimalNumberTextField(viewModel: viewModel.amountDecimalNumberTextFieldViewModel)
                    .alignment(.center)
                    .prefixSuffixOptions(viewModel.amountFieldOptions)
                    .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                    .allowsHitTesting(false) // This text field is read-only

                // Keep empty text so that the view maintains its place in the layout
                Text(viewModel.alternativeAmount ?? " ")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
            .infinityFrame(axis: .horizontal, alignment: .center)
        }
        .padding(.top, 4)
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 20, horizontalPadding: 14)
    }
}
