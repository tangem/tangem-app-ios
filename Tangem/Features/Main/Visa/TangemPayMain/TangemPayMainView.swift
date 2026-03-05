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

                ForEach(viewModel.pendingExpressTransactions) { transactionInfo in
                    PendingExpressTransactionView(info: transactionInfo)
                }

                NotificationView(input: viewModel.contactSupportNotificationInput)

                TransactionsListView(
                    state: viewModel.tangemPayTransactionHistoryState,
                    exploreAction: nil,
                    exploreConfirmationDialog: nil,
                    exploreTransactionAction: viewModel.openTransactionDetails,
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
        .alert(item: $viewModel.alert) { $0.alert }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: viewModel.onPin) {
                        Label(
                            Localization.visaOnboardingPinCodeNavigationTitle,
                            systemImage: "circle.grid.3x3.fill"
                        )
                    }
                    .disabled(viewModel.freezingState.isFreezingUnfreezingInProgress)

                    Button(action: viewModel.termsAndLimits) {
                        Label(
                            Localization.tangemPayTermsLimits,
                            systemImage: "text.page.fill"
                        )
                    }
                    .onAppear { viewModel.onToolbarClicked() }

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
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 7) {
                Text(Localization.tangempayTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                LoadableBalanceView(
                    state: viewModel.balance,
                    style: .init(font: Fonts.Regular.title1, textColor: Colors.Text.primary1),
                    loader: .init(size: .init(width: 102, height: 24), cornerRadius: 6)
                )
                .padding(.bottom, 5)

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
                        FixedSizeButtonWithIconInfo(
                            title: Localization.tangempayCardDetailsWithdraw,
                            icon: Assets.arrowUpMini,
                            loading: viewModel.isWithdrawButtonLoading,
                            disabled: viewModel.freezingState.shouldDisableActionButtons,
                            action: viewModel.withdraw
                        ),
                    ]
                )
            }
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}
