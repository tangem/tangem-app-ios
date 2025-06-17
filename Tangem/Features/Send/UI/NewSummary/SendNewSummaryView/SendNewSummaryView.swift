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
        VStack(alignment: .center, spacing: 14) {
            GroupedScrollView(spacing: 14) {
                amountSectionView

                destinationSectionView

                feeSectionView

                notificationsView
            }

            descriptionView
        }
        .transition(transitionService.newSummaryViewTransition())
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    // MARK: - Amount

    @ViewBuilder
    private var amountSectionView: some View {
        GroupedSection(viewModel.sendAmountCompactViewModel) {
            SendNewAmountCompactView(viewModel: $0)
        }
        .backgroundColor(Colors.Background.action)
        .innerContentPadding(0)
        .horizontalPadding(0)
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
            Button(action: viewModel.userDidTapFee) {
                SendNewFeeCompactView(viewModel: feeCompactViewModel)
            }
            .disabled(!feeCompactViewModel.canEditFee)
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
            Text(.init(transactionDescription))
                .style(Fonts.Regular.caption1, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .visible(viewModel.transactionDescriptionIsVisible)
        }
    }
}
