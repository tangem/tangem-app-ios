//
//  VisaMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct VisaWalletMainContentView: View {
    @ObservedObject var viewModel: VisaWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            MainButton(
                title: "Deposit",
                icon: .leading(Assets.arrowDownMini),
                style: .primary,
                size: .default,
                isLoading: false,
                isDisabled: false,
                action: viewModel.openDeposit
            )

            Button(action: viewModel.openBalancesAndLimits, label: {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Balances & Limits")
                            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(viewModel.cryptoLimitText)
                                .style(Fonts.Regular.footnote, color: Colors.Text.primary1)

                            Text(viewModel.numberOfDaysLimitText)
                                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        }
                    }

                    Spacer()

                    Assets.chevronRight.image
                }
                .defaultRoundedBackground()
            })

            TransactionsListView(
                state: viewModel.transactionListViewState,
                exploreAction: viewModel.openExplorer,
                exploreTransactionAction: viewModel.exploreTransaction(with:),
                reloadButtonAction: viewModel.reloadTransactionHistory,
                isReloadButtonBusy: viewModel.isTransactoinHistoryReloading,
                fetchMore: viewModel.fetchNextTransactionHistoryPage()
            )
        }
        .padding(.horizontal, 16)
        .bottomSheet(item: $viewModel.balancesAndLimitsViewModel, settings: .init(backgroundColor: Colors.Background.tertiary)) { model in
            VisaBalancesLimitsBottomSheetView(viewModel: model)
        }
    }
}

#Preview {
    let userWalletModel = FakeUserWalletModel.visa
    let visaUtils = VisaUtilities()
    let coordinator = MainCoordinator()
    let viewModel = VisaWalletMainContentViewModel(
        walletModel: visaUtils.getVisaWalletModel(for: userWalletModel),
        coordinator: coordinator
    )

    return VisaWalletMainContentView(viewModel: viewModel)
}
