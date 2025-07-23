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
    let transitionService: SendTransitionService
    let namespace: SendSummaryView.Namespace

    var body: some View {
        GroupedScrollView(spacing: 14) {
            if viewModel.showHeader, let transactionTime = viewModel.transactionSentTime {
                header(transactionTime: transactionTime)
            }

            if let sendAmountFinishViewModel = viewModel.sendAmountFinishViewModel {
                SendNewAmountFinishView(viewModel: sendAmountFinishViewModel)
            }

            if let sendDestinationCompactViewModel = viewModel.sendDestinationCompactViewModel {
                SendNewDestinationCompactView(viewModel: sendDestinationCompactViewModel)
            }

            if let sendFeeCompactViewModel = viewModel.sendFeeCompactViewModel {
                SendFeeCompactView(
                    viewModel: sendFeeCompactViewModel,
                    type: .enabled(),
                    namespace: .init(id: namespace.id, names: namespace.names)
                )
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .transition(transitionService.newFinishViewTransition())
    }

    // MARK: - Header

    @ViewBuilder
    private func header(transactionTime: String) -> some View {
        VStack(spacing: 12) {
            Assets.inProgress.image
                .resizable()
                .frame(width: 56, height: 56)

            VStack(spacing: 4) {
                Text(Localization.commonInProgress)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)

                Text(transactionTime)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .lineLimit(1)
        }
        .transition(.offset(y: -30).combined(with: .opacity).animation(SendTransitionService.Constants.newAnimation))
        .padding(.bottom, 10)
    }
}
