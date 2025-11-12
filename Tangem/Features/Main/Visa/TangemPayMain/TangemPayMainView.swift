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
                TangemPayCardDetailsView(viewModel: viewModel.tangemPayCardDetailsViewModel)

                if viewModel.freezingState.shouldShowUnfreezeButton {
                    MainButton(
                        settings: .init(
                            title: Localization.tangempayCardDetailsUnfreezeCard,
                            style: .primary,
                            size: .default,
                            action: viewModel.unfreeze
                        )
                    )
                }

                if viewModel.shouldDisplayAddToApplePayGuide {
                    Button(action: viewModel.openAddToApplePayGuide) {
                        TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(
                        action: viewModel.freezingState.isFrozen
                            ? viewModel.unfreeze
                            : viewModel.showFreezePopup
                    ) {
                        Label(
                            viewModel.freezingState.isFrozen
                                ? Localization.tangempayCardDetailsUnfreezeCard
                                : Localization.tangempayCardDetailsFreezeCard,
                            systemImage: "snowflake"
                        )
                    }
                    .disabled(viewModel.freezingState.isFreezingUnfreezingInProgress)
                } label: {
                    NavbarDotsImage()
                }
            }
        }
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
                        disabled: viewModel.freezingState.shouldDisableActionButtons,
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
