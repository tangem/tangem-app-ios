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

    var body: some View {
        GroupedScrollView(spacing: 14) {
            amountSectionView

            nftSectionView

            destinationSectionView

            feeSectionView

            notificationsView
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            descriptionView
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    // MARK: - Amount

    @ViewBuilder
    private var amountSectionView: some View {
        if let sendAmountCompactViewModel = viewModel.sendAmountCompactViewModel {
            SendNewAmountCompactView(viewModel: sendAmountCompactViewModel)
                .allowsHitTesting(viewModel.amountCompactViewType.editable)
        }
    }

    // MARK: - NFT

    @ViewBuilder
    private var nftSectionView: some View {
        if let nftAssetCompactViewModel = viewModel.nftAssetCompactViewModel {
            NFTAssetCompactView(viewModel: nftAssetCompactViewModel)
        }
    }

    // MARK: - Destination

    @ViewBuilder
    private var destinationSectionView: some View {
        if let destinationCompactViewModel = viewModel.sendDestinationCompactViewModel {
            Button(action: viewModel.userDidTapDestination) {
                SendDestinationCompactView(viewModel: destinationCompactViewModel)
            }
            .allowsHitTesting(viewModel.destinationCompactViewType.editable)
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
                .padding(.vertical, 8)
                .infinityFrame(axis: .horizontal)
                .background(Colors.Background.tertiary)
                .visible(viewModel.transactionDescriptionIsVisible)
        }
    }
}
