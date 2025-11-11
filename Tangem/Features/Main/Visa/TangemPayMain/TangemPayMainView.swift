//
//  TangemPayMainView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct TangemPayMainView: View {
    @ObservedObject var viewModel: TangemPayMainViewModel

    var body: some View {
        RefreshScrollView(stateObject: viewModel.refreshScrollViewStateObject) {
            VStack(spacing: 14) {
                if let tangemPayCardDetailsViewModel = viewModel.tangemPayCardDetailsViewModel {
                    TangemPayCardDetailsView(viewModel: tangemPayCardDetailsViewModel)
                }

                if viewModel.shouldDisplayAddToApplePayGuide {
                    Button(action: viewModel.openAddToApplePayGuide) {
                        TangemPayAddToApplePayBanner()
                    }
                }

                balance

                TransactionsListView(
                    state: viewModel.tangemPayTransactionHistoryState,
                    exploreAction: nil,
                    exploreTransactionAction: { _ in },
                    reloadButtonAction: viewModel.reloadHistory,
                    isReloadButtonBusy: false,
                    fetchMore: viewModel.fetchNextTransactionHistoryPage()
                )

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Colors.Background.secondary)
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }

    var balance: some View {
        VStack(spacing: .zero) {
            MainHeaderView(viewModel: viewModel.mainHeaderViewModel)
                .fixedSize(horizontal: false, vertical: true)

            ScrollableButtonsView(
                itemsHorizontalOffset: 14,
                itemsVerticalOffset: 3,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(
                        title: Localization.tangempayCardDetailsAddFunds,
                        icon: Assets.plus14,
                        disabled: false,
                        action: viewModel.addFunds
                    ),
                ]
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}
