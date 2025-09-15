//
//  SendNewAmountCompactView.swift
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

struct SendNewAmountCompactView: View {
    @ObservedObject var viewModel: SendNewAmountCompactViewModel
    @State private var separatorSize: CGSize = .zero

    var body: some View {
        VStack(spacing: .zero) {
            Button(action: viewModel.userDidTapAmount) {
                SendNewAmountCompactTokenView(viewModel: viewModel.sendAmountCompactViewModel)
            }

            if let receiveTokenViewModel = viewModel.sendReceiveTokenCompactViewModel {
                FixedSpacer(length: 8)

                Button(action: viewModel.userDidTapReceiveTokenAmount) {
                    SendNewAmountCompactTokenView(viewModel: receiveTokenViewModel)
                }
                .overlay(alignment: .top) {
                    SendNewAmountCompactViewSeparator(style: viewModel.amountsSeparator)
                        .readGeometry(\.frame.size, bindTo: $separatorSize)
                        .offset(y: -separatorSize.height / 2 - 4) // Half spacer length
                }
            }

            if let sendSwapProviderCompactViewData = viewModel.sendSwapProviderCompactViewData {
                Separator(color: Colors.Stroke.primary)
                    .padding(.horizontal, 14)

                Button(action: viewModel.userDidTapProvider) {
                    SendSwapProviderCompactView(
                        data: sendSwapProviderCompactViewData,
                        shouldAnimateBestRateBadge: $viewModel.shouldAnimateBestRateBadge
                    )
                }
                .disabled(!sendSwapProviderCompactViewData.isTappable)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)
    }
}
