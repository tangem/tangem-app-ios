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
import TangemUIUtils
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayMainView: View {
    @ObservedObject var viewModel: TangemPayMainViewModel

    @StateObject private var scrollOffsetHandler = ScrollViewOffsetHandler.tokenDetails(
        tokenIconSizeSettings: Constants.tokenIconSizeSettings,
        headerTopPadding: Constants.headerTopPadding
    )

    var body: some View {
        // This scroll view must use non-lazy content settings because the transactions list view
        // and other subviews already contain inner lazy stacks.
        // Nested lazy stacks are known to cause various issues with scroll offset handling and content rendering.
        RefreshScrollView(stateObject: viewModel.refreshScrollViewStateObject, contentSettings: .simpleContent) {
            VStack(spacing: 14) {
                header

                ForEach(viewModel.inlineNotifications) { notification in
                    NotificationView(input: notification)
                }

                balanceCard

                if viewModel.shouldDisplayAddToApplePayGuide {
                    Button(action: viewModel.openAddToApplePayGuide) {
                        TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
                    }
                }

                if viewModel.hasIssuingEntry {
                    TangemPayIssuingCardBanner()
                }

                if let cardDeactivatedNotificationInput = viewModel.cardDeactivatedNotificationInput {
                    NotificationView(input: cardDeactivatedNotificationInput)
                }

                ForEach(viewModel.pendingExpressTransactions) { transactionInfo in
                    PendingExpressTransactionView(info: transactionInfo)
                }

                if !viewModel.isDeactivated {
                    TransactionsListView(
                        state: viewModel.tangemPayTransactionHistoryState,
                        exploreAction: nil,
                        exploreConfirmationDialog: nil,
                        exploreTransactionAction: viewModel.openTransactionDetails,
                        reloadButtonAction: viewModel.reloadHistory,
                        isReloadButtonBusy: false,
                        fetchMore: viewModel.fetchNextTransactionHistoryPage()
                    )
                    .opacity(viewModel.isStale ? 0.6 : 1)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .readContentOffset(
                inCoordinateSpace: .named(Constants.coordinateSpaceName),
                bindTo: scrollOffsetHandler.contentOffsetSubject.asWriteOnlyBinding(.zero)
            )
        }
        .background(Colors.Background.secondary)
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: scrollOffsetHandler.onViewAppear)
        .alert(item: $viewModel.alert) { $0.alert }
        .coordinateSpace(name: Constants.coordinateSpaceName)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(Localization.tangempayPaymentAccount)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    .opacity(scrollOffsetHandler.state)
                    .animation(.easeInOut(duration: 0.2), value: scrollOffsetHandler.state)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: viewModel.termsAndLimits) {
                        Label(
                            Localization.tangemPayTermsLimits,
                            systemImage: "text.page"
                        )
                    }

                    Button(action: viewModel.contactSupport) {
                        Label(
                            Localization.tangempayPaySupport,
                            systemImage: "text.bubble"
                        )
                    }
                } label: {
                    NavbarDotsImage()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.tangempayPaymentAccount)
                .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)

            HStack(alignment: .center, spacing: 6) {
                HStack(alignment: .center, spacing: -4) {
                    Assets.Visa.usdc.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .zIndex(1)

                    Assets.Visa.pol.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .mask {
                            Rectangle()
                                .overlay {
                                    Circle()
                                        .frame(width: 22, height: 22)
                                        .offset(x: -14)
                                        .blendMode(.destinationOut)
                                }
                                .compositingGroup()
                        }
                }

                Text(Localization.tangempayUsdcOnPolygonNetwork)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(Localization.tangempayAvailableBalance)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

            LoadableBalanceView(
                state: viewModel.balance,
                style: .init(font: Fonts.Regular.title1, textColor: Colors.Text.primary1),
                loader: .init(size: .init(width: 102, height: 24), cornerRadius: 6),
                accessibilityIdentifier: TangemPayAccessibilityIdentifiers.paymentAccountBalance
            )
            .opacity(viewModel.isStale ? 0.6 : 1)

            cardListRow
                .padding(.vertical, 4)

            ScrollableButtonsView(
                itemsHorizontalOffset: 14,
                itemsVerticalOffset: 3,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(
                        title: Localization.tangempayCardDetailsAddFunds,
                        icon: Assets.plus14,
                        disabled: viewModel.actionButtonsDisabled,
                        action: viewModel.addFunds
                    ),
                    FixedSizeButtonWithIconInfo(
                        title: Localization.tangempayCardDetailsWithdraw,
                        icon: Assets.arrowUpMini,
                        loading: viewModel.isWithdrawButtonLoading,
                        disabled: viewModel.actionButtonsDisabled,
                        action: viewModel.withdraw
                    ),
                ]
            )
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    private var cardListRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.cardEntries) { entry in
                cardEntryButton(for: entry)
            }

            Button(action: viewModel.tapAddCard) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Colors.Text.tertiary)
                    .frame(width: 48, height: 32)
                    .background(Colors.Button.secondary.cornerRadiusContinuous(4))
            }
            .disabled(viewModel.isStale)
            .opacity(viewModel.isStale ? 0.6 : 1)

            Spacer()
        }
    }

    @ViewBuilder
    private func cardEntryButton(for entry: TangemPayCardEntry) -> some View {
        switch entry {
        case .issued(let card):
            Button {
                viewModel.openCardManagement(entry: entry)
            } label: {
                TangemPaySmallCardView(
                    state: card.isReissuing
                        ? .replacing
                        : .issued(cardNumberEnd: card.cardNumberEnd)
                )
            }
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.paymentAccountCardButton(cardId: card.cardId))
            .disabled(viewModel.isStale)
            .opacity(viewModel.isStale ? 0.6 : 1)
        case .issuing:
            Button {
                viewModel.openCardManagement(entry: entry)
            } label: {
                TangemPaySmallCardView(state: .issuing)
            }
        }
    }
}

private extension TangemPayMainView {
    enum Constants {
        static let tokenIconSizeSettings: IconViewSizeSettings = .tokenDetails
        static let headerTopPadding: CGFloat = 14.0
        static let coordinateSpaceName = "TangemPayMainView.coordinateSpaceName"
    }
}
