//
//  SendNewFinishView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct SendNewFinishView: View {
    @ObservedObject var viewModel: SendNewFinishViewModel

    var body: some View {
        GroupedScrollView(spacing: 14) {
            if viewModel.showHeader, let transactionTime = viewModel.transactionSentTime {
                header(transactionTime: transactionTime)
            }

            if let sendAmountFinishViewModel = viewModel.sendAmountFinishViewModel {
                SendNewAmountFinishView(viewModel: sendAmountFinishViewModel)
            }

            if let nftAssetCompactViewModel = viewModel.nftAssetCompactViewModel {
                NFTAssetCompactView(viewModel: nftAssetCompactViewModel)
            }

            if let sendDestinationCompactViewModel = viewModel.sendDestinationCompactViewModel {
                SendNewDestinationCompactView(viewModel: sendDestinationCompactViewModel)
            }

            if let sendFeeCompactViewModel = viewModel.sendFeeFinishViewModel {
                SendFeeFinishView(viewModel: sendFeeCompactViewModel)
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            if let url = viewModel.transactionURL {
                bottomButtons(url: url)
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func header(transactionTime: String) -> some View {
        VStack(spacing: 12) {
            Assets.inProgress.image
                .resizable()
                .frame(width: 56, height: 56)

            VStack(spacing: 4) {
                Text(Localization.sentTransactionSentTitle)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(transactionTime)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .lineLimit(1)
        }
        .transition(
            .offset(y: -30)
                .combined(with: .opacity)
                .animation(SendTransitions.animation)
        )
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func bottomButtons(url: URL) -> some View {
        HStack(spacing: 8) {
            MainButton(
                title: Localization.commonExplore,
                icon: .leading(Assets.Glyphs.explore),
                style: .secondary,
                action: { viewModel.explore(url: url) }
            )
            MainButton(
                title: Localization.commonShare,
                icon: .leading(Assets.share),
                style: .secondary,
                action: { viewModel.share(url: url) }
            )
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 16)
        .transition(
            .opacity.animation(SendTransitions.animation)
        )
    }
}
