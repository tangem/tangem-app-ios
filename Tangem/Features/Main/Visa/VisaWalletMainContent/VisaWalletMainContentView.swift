//
//  VisaMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils

struct VisaWalletMainContentView: View {
    @ObservedObject var viewModel: VisaWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            ScrollableButtonsView(
                itemsHorizontalOffset: 14,
                itemsVerticalOffset: 3,
                buttonsInfo: viewModel.buttons
            )

            balancesAndLimitsView

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .transition(.notificationTransition)
            }

            TransactionsListView(
                state: viewModel.transactionListViewState,
                exploreAction: viewModel.openExplorer,
                exploreConfirmationDialog: nil,
                exploreTransactionAction: viewModel.exploreTransaction(with:),
                reloadButtonAction: viewModel.reloadTransactionHistory,
                isReloadButtonBusy: viewModel.isTransactionHistoryReloading,
                fetchMore: viewModel.fetchNextTransactionHistoryPage()
            )
        }
        .padding(.horizontal, 16)
        .bottomSheet(item: $viewModel.balancesAndLimitsViewModel, backgroundColor: Colors.Background.tertiary) { model in
            VisaBalancesLimitsBottomSheetView(viewModel: model)
        }
        .bindAlert($viewModel.alert)
    }

    @ViewBuilder
    private var balancesAndLimitsView: some View {
        if let input = viewModel.failedToLoadInfoNotificationInput {
            NotificationView(input: input)
                .setButtonsLoadingState(to: viewModel.isScannerBusy)
                .transition(.notificationTransition)
        } else {
            Button(action: viewModel.openBalancesAndLimits, label: {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Localization.visaMainBalancesAndLimits)
                            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(viewModel.cryptoLimitText)
                                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                            Text(viewModel.numberOfDaysLimitText)
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        }
                        .skeletonable(isShown: viewModel.isBalancesAndLimitsBlockLoading, size: .init(width: 160, height: 18), radius: 4)
                    }

                    Spacer()

                    Assets.chevronRight.image
                }
                .defaultRoundedBackground()
            })
        }
    }
}
