//
//  SendFinishView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct SendFinishView: View {
    @ObservedObject var viewModel: SendFinishViewModel

    var body: some View {
        GroupedScrollView(spacing: 14) {
            if viewModel.showHeader, let transactionTime = viewModel.transactionSentTime {
                header(transactionTime: transactionTime)
            }

            if let sendAmountCompactViewModel = viewModel.sendAmountCompactViewModel {
                SendAmountCompactView(
                    viewModel: sendAmountCompactViewModel,
                    type: .enabled()
                )
            }

            if let onrampAmountCompactViewModel = viewModel.onrampAmountCompactViewModel {
                OnrampAmountCompactView(
                    viewModel: onrampAmountCompactViewModel
                )
            }

            if let stakingValidatorsCompactViewModel = viewModel.stakingValidatorsCompactViewModel {
                StakingValidatorsCompactView(
                    viewModel: stakingValidatorsCompactViewModel,
                    type: .enabled()
                )
            }

            if let sendFeeCompactViewModel = viewModel.sendFeeCompactViewModel {
                SendFeeCompactView(
                    viewModel: sendFeeCompactViewModel,
                    type: .enabled()
                )
            }

            if let onrampStatusCompactViewModel = viewModel.onrampStatusCompactViewModel {
                OnrampStatusCompactView(viewModel: onrampStatusCompactViewModel)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            if let url = viewModel.transactionURL {
                bottomButtons(url: url)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }

    // MARK: - Header

    @ViewBuilder
    private func header(transactionTime: String) -> some View {
        VStack(spacing: 18) {
            Assets.inProgress.image

            VStack(spacing: 6) {
                Text(Localization.commonInProgress)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(transactionTime)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    .lineLimit(1)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .padding(.top, 4)
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
        .transition(.opacity.animation(SendTransitions.animation))
    }
}
