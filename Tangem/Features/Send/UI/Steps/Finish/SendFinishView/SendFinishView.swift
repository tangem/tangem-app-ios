//
//  SendFinishView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct SendFinishView: View {
    @ObservedObject var viewModel: SendFinishViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 14)) {
            if viewModel.showHeader, let transactionTime = viewModel.transactionSentTime {
                header(transactionTime: transactionTime)
            }

            if let sendAmountFinishViewModel = viewModel.sendAmountFinishViewModel {
                SendAmountFinishView(viewModel: sendAmountFinishViewModel)
            }

            if let onrampAmountCompactViewModel = viewModel.onrampAmountCompactViewModel {
                OnrampAmountCompactView(viewModel: onrampAmountCompactViewModel)
            }

            if let nftAssetCompactViewModel = viewModel.nftAssetCompactViewModel {
                NFTAssetCompactView(viewModel: nftAssetCompactViewModel)
            }

            if let sendDestinationCompactViewModel = viewModel.sendDestinationCompactViewModel {
                SendDestinationCompactView(viewModel: sendDestinationCompactViewModel)
            }

            if let stakingTargetsCompactViewModel = viewModel.stakingTargetsCompactViewModel {
                StakingTargetsCompactView(viewModel: stakingTargetsCompactViewModel)
            }

            if let sendFeeCompactViewModel = viewModel.sendFeeFinishViewModel {
                SendFeeFinishView(viewModel: sendFeeCompactViewModel)
            }

            if let onrampStatusCompactViewModel = viewModel.onrampStatusCompactViewModel {
                OnrampStatusCompactView(viewModel: onrampStatusCompactViewModel)
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

    private func header(transactionTime: String) -> some View {
        VStack(spacing: 12) {
            Assets.inProgress.image
                .resizable()
                .frame(width: 56, height: 56)

            VStack(spacing: 4) {
                Text(viewModel.headerTitle)
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
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .transition(
            .opacity.animation(SendTransitions.animation)
        )
    }
}
