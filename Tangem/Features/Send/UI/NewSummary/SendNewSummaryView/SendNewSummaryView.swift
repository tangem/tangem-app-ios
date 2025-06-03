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
            }

            descriptionView
        }
        .transition(transitionService.newSummaryViewTransition(isEditMode: viewModel.isEditMode))
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    // MARK: - Amount

    @ViewBuilder
    private var amountSectionView: some View {
        ZStack(alignment: .center) {
            VStack(spacing: .zero) {
                if let amountCompactViewModel = viewModel.sendAmountCompactViewModel {
                    Button(action: viewModel.userDidTapAmount) {
                        SendNewAmountCompactView(viewModel: amountCompactViewModel)
                    }
                }

                if let receiveTokenViewModel = viewModel.sendReceiveTokenCompactViewModel {
                    Button(action: viewModel.userDidTapReceiveTokenAmount) {
                        SendNewAmountCompactView(viewModel: receiveTokenViewModel)
                    }
                }
            }

            if let separatorStyle = viewModel.sendAmountsSeparator {
                SendNewAmountCompactViewSeparator(style: separatorStyle)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)
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
