//
//  SendSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct SendSummaryView: View {
    @ObservedObject var viewModel: SendSummaryViewModel

    /// We use ZStack for each step to hold the place where
    /// the compact version of the step will be appeared.
    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            GroupedScrollView(spacing: 14) {
                if let sendAmountViewModel = viewModel.sendAmountCompactViewModel {
                    SendAmountCompactView(
                        viewModel: sendAmountViewModel,
                        type: viewModel.amountCompactViewType
                    )
                    .infinityFrame(axis: .horizontal)
                }

                if let stakingValidatorsCompactViewModel = viewModel.stakingValidatorsCompactViewModel {
                    StakingValidatorsCompactView(
                        viewModel: stakingValidatorsCompactViewModel,
                        type: stakingValidatorsCompactViewModel.canEditValidator ? .enabled(action: viewModel.userDidTapValidator) : .disabled
                    )
                    .infinityFrame(axis: .horizontal)
                }

                if let sendFeeCompactViewModel = viewModel.sendFeeCompactViewModel {
                    SendFeeCompactView(
                        viewModel: sendFeeCompactViewModel,
                        type: .enabled(action: viewModel.userDidTapFee)
                    )
                    .infinityFrame(axis: .horizontal)
                }

                if viewModel.showHint {
                    HintView(
                        text: Localization.sendSummaryTapHint,
                        font: Fonts.Regular.footnote,
                        textColor: Colors.Text.secondary,
                        backgroundColor: Colors.Button.secondary
                    )
                    .padding(.top, 8)
                    .transition(
                        .asymmetric(insertion: .offset(y: 20), removal: .identity).combined(with: .opacity)
                    )
                }

                ForEach(viewModel.notificationInputs) { input in
                    NotificationView(input: input)
                        .setButtonsLoadingState(to: viewModel.notificationButtonIsLoading)
                }
            }

            descriptionView
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    // MARK: - Description

    @ViewBuilder
    private var descriptionView: some View {
        if let transactionDescription = viewModel.transactionDescription {
            Text(transactionDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .visible(viewModel.transactionDescriptionIsVisible)
        }
    }
}
