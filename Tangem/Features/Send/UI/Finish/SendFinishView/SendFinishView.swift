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
    let namespace: SendSummaryView.Namespace

    var body: some View {
        GroupedScrollView(spacing: 14) {
            FixedSpacer(height: 20)

            if viewModel.showHeader, let transactionTime = viewModel.transactionSentTime {
                header(transactionTime: transactionTime)
            }

            if let sendDestinationCompactViewModel = viewModel.sendDestinationCompactViewModel {
                SendDestinationCompactView(
                    viewModel: sendDestinationCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }

            if let sendAmountCompactViewModel = viewModel.sendAmountCompactViewModel {
                SendAmountCompactView(
                    viewModel: sendAmountCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }

            if let onrampAmountCompactViewModel = viewModel.onrampAmountCompactViewModel {
                OnrampAmountCompactView(
                    viewModel: onrampAmountCompactViewModel,
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }

            if let stakingValidatorsCompactViewModel = viewModel.stakingValidatorsCompactViewModel {
                StakingValidatorsCompactView(
                    viewModel: stakingValidatorsCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }

            if let sendFeeCompactViewModel = viewModel.sendFeeCompactViewModel {
                SendFeeCompactView(
                    viewModel: sendFeeCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }

            if let onrampStatusCompactViewModel = viewModel.onrampStatusCompactViewModel {
                OnrampStatusCompactView(viewModel: onrampStatusCompactViewModel)
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
}
