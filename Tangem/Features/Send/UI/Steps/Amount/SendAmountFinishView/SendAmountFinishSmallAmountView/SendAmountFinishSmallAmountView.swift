//
//  SendAmountFinishSmallAmountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct SendAmountFinishSmallAmountView: View {
    let viewModel: SendAmountFinishSmallAmountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SendTokenHeaderView(header: viewModel.tokenHeader)

            HStack(spacing: 14) {
                TokenIcon(
                    tokenIconInfo: viewModel.tokenIconInfo,
                    size: CGSize(width: 36, height: 36)
                )

                VStack(alignment: .leading, spacing: 4) {
                    SendDecimalNumberTextField(viewModel: viewModel.amountDecimalNumberTextFieldViewModel)
                        .appearance(.init(font: Fonts.Bold.subheadline, textColor: Colors.Text.primary1))
                        .alignment(.leading)
                        .prefixSuffixOptions(viewModel.amountFieldOptions)
                        .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                        .allowsHitTesting(false) // This text field is read-only

                    Text(viewModel.alternativeAmount ?? " ")
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 14, horizontalPadding: 14)
    }
}
