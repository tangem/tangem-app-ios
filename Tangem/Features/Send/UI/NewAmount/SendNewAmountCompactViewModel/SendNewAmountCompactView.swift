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

    var body: some View {
        VStack(spacing: .zero) {
            Button(action: viewModel.userDidTapAmount) {
                SendNewAmountCompactTokenView(viewModel: viewModel.sendAmountCompactViewModel)
            }

            if let receiveTokenViewModel = viewModel.sendReceiveTokenCompactViewModel {
                Button(action: viewModel.userDidTapReceiveTokenAmount) {
                    SendNewAmountCompactTokenView(viewModel: receiveTokenViewModel)
                }
                .overlay(alignment: .top) {
                    SendNewAmountCompactViewSeparator(style: viewModel.amountsSeparator)
                        .offset(y: -14)
                }
            }

            if let sendSwapProviderCompactViewData = viewModel.sendSwapProviderCompactViewData {
                Separator(color: Colors.Stroke.primary)
                    .padding(.horizontal, 14)

                Button(action: viewModel.userDidTapProvider) {
                    SendSwapProviderCompactView(data: sendSwapProviderCompactViewData)
                }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)
    }
}
