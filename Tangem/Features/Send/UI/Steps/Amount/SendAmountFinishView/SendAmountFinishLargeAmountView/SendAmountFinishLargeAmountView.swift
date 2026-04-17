//
//  SendAmountFinishLargeAmountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct SendAmountFinishLargeAmountView: View {
    let viewModel: SendAmountFinishLargeAmountViewModel

    var body: some View {
        VStack(spacing: 16) {
            if let tokenHeader = viewModel.tokenHeader {
                SendTokenHeaderView(header: tokenHeader)
                    .padding(.bottom, 8.0)
            }

            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: CGSize(width: 36, height: 36),
                // Kingfisher shows a grey background even if there has a cached image
                forceKingfisher: false
            )

            VStack(alignment: .center, spacing: 4) {
                Text(viewModel.amountText)
                    .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                    .lineLimit(1)
                    .minimumScaleFactor(SendAmountStep.Constants.amountMinTextScale)

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
