//
//  OnrampAmountCompactView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct OnrampAmountCompactView: View {
    @ObservedObject var viewModel: OnrampAmountCompactViewModel

    var body: some View {
        amountContent
            .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var amountContent: some View {
        VStack(spacing: 16) {
            IconView(
                url: viewModel.fiatIconURL,
                size: CGSize(width: 36, height: 36),
                // Kingfisher shows a gray background even if it has a cached image
                forceKingfisher: false
            )

            VStack(spacing: 12) {
                textView

                providerView
            }
        }
        .padding(.top, 4)
    }

    private var textView: some View {
        VStack(spacing: 6) {
            SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                .alignment(.center)
                .prefixSuffixOptions(viewModel.currentFieldOptions)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .disabled(true) // TextField is read only

            // Keep empty text so that the view maintains its place in the layout
            Text(viewModel.alternativeAmount ?? " ")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
    }

    private var providerView: some View {
        HStack(spacing: 6) {
            Text("with")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

            IconView(
                url: viewModel.providerIconURL,
                size: CGSize(width: 16, height: 16),
                // Kingfisher shows a gray background even if it has a cached image
                forceKingfisher: false
            )

            Text(viewModel.providerName ?? "")
                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)
        }
    }
}
