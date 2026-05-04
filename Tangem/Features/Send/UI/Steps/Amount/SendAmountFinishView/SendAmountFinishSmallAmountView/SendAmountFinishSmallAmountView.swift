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
                    Text(viewModel.amountText)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .lineLimit(1)
                        .minimumScaleFactor(SendAmountStep.Constants.amountMinTextScale)

                    Text(viewModel.alternativeAmount ?? " ")
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
                .infinityFrame(axis: .horizontal, alignment: .leading)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 14, horizontalPadding: 14)
    }
}
