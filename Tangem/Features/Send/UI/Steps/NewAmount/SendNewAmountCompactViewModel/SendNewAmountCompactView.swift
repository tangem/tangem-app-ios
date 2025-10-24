//
//  SendNewAmountCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct SendNewAmountCompactView: View {
    @ObservedObject var viewModel: SendNewAmountCompactViewModel
    @State private var separatorSize: CGSize = .zero

    private var tappable: Bool = true

    init(viewModel: SendNewAmountCompactViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            Button(action: viewModel.userDidTapAmount) {
                SendNewAmountCompactTokenView(viewModel: viewModel.sendAmountCompactViewModel)
            }
            .allowsHitTesting(tappable)

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
                .allowsHitTesting(tappable)
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
                .allowsHitTesting(tappable)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)
    }
}

// MARK: - Setupable

extension SendNewAmountCompactView: Setupable {
    func tappable(_ tappable: Bool) -> Self {
        map { $0.tappable = tappable }
    }
}
