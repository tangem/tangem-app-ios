//
//  SendNewSummaryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct SendNewSummaryView: View {
    @ObservedObject var viewModel: SendNewSummaryViewModel
    let transitionService: SendTransitionService

    var body: some View {
        GroupedScrollView(spacing: 14) {
            amountSectionView

            destinationSectionView

            feeSectionView

            notificationsView
        }
        .safeAreaInset(edge: .bottom, content: {
            descriptionView
        })
        .transition(transitionService.newSummaryViewTransition())
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    // MARK: - Amount

    @ViewBuilder
    private var amountSectionView: some View {
        if let sendAmountCompactViewModel = viewModel.sendAmountCompactViewModel {
            SendNewAmountCompactView(viewModel: sendAmountCompactViewModel)
        }
    }

    // MARK: - Destination

    @ViewBuilder
    private var destinationSectionView: some View {
        if let destinationCompactViewModel = viewModel.sendDestinationCompactViewModel {
            Button(action: viewModel.userDidTapDestination) {
                SendNewDestinationCompactView(viewModel: destinationCompactViewModel)
            }
        }
    }

    // MARK: - Fee

    @ViewBuilder
    private var feeSectionView: some View {
        if let feeCompactViewModel = viewModel.sendFeeCompactViewModel {
            if feeCompactViewModel.canEditFee {
                Button(action: viewModel.userDidTapFee) { SendNewFeeCompactView(viewModel: feeCompactViewModel) }
            } else {
                SendNewFeeCompactView(viewModel: feeCompactViewModel)
            }
        }
    }

    // MARK: - Notifications

    @ViewBuilder
    private var notificationsView: some View {
        ForEach(viewModel.notificationInputs) { input in
            NotificationView(input: input)
                .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
        }
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionView: some View {
        if let transactionDescription = viewModel.transactionDescription {
            Text(transactionDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .infinityFrame(axis: .horizontal)
                .background(Colors.Background.tertiary)
                .visible(viewModel.transactionDescriptionIsVisible)
        }
    }
}
