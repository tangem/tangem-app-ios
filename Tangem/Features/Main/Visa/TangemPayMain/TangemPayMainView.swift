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
import TangemFoundation
import TangemLocalization
import TangemAccessibilityIdentifiers

struct TangemPayMainView: View {
    @ObservedObject var viewModel: TangemPayMainViewModel

    @StateObject private var scrollOffsetHandler = ScrollViewOffsetHandler.tokenDetails(
        tokenIconSizeSettings: Constants.tokenIconSizeSettings,
        headerTopPadding: Constants.headerTopPadding
    )

    @StateObject private var elasticContainerModel: TangemElasticContainerModel
    @State private var headerHeightRatio: CGFloat = 1
    @State private var visibleBodyHeight: CGFloat = 0

    init(viewModel: TangemPayMainViewModel) {
        self.viewModel = viewModel
        _elasticContainerModel = StateObject(
            wrappedValue: TangemElasticContainerModel(
                scrollViewInteractor: viewModel.refreshScrollViewStateObject.scrollViewInteractor
            )
        )
    }

    var body: some View {
        if FeatureProvider.isAvailable(.tangemPaySpendRedesign) {
            redesignedBody
        } else {
            legacyBody
        }
    }

    // MARK: - Legacy

    private var legacyBody: some View {
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

                if !viewModel.multipleCardsEnabled, viewModel.shouldDisplayReplacingCardBanner {
                    TangemPayReplacingCardBanner()
                }

                if viewModel.shouldDisplayAddToApplePayGuide {
                    Button(action: viewModel.openAddToApplePayGuide) {
                        TangemPayAddToApplePayBanner(closeAction: viewModel.dismissAddToApplePayGuideBanner)
                    }
                }

                if viewModel.multipleCardsEnabled, viewModel.hasIssuingEntry {
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
                    .opacity(viewModel.shouldDimTransactions ? 0.6 : 1)
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
        .onDisappear(perform: viewModel.onDisappear)
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
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.moreActionsButton)
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

            Group {
                if viewModel.multipleCardsEnabled {
                    cardListRow
                } else {
                    cardIconRow
                }
            }
            .padding(.vertical, 4)

            ScrollableButtonsView(
                itemsHorizontalOffset: 14,
                itemsVerticalOffset: 3,
                buttonsInfo: [
                    FixedSizeButtonWithIconInfo(
                        title: Localization.tangempayCardDetailsAddFunds,
                        icon: Assets.plus14,
                        disabled: viewModel.actionButtonsDisabled,
                        action: viewModel.addFunds,
                        accessibilityIdentifier: TangemPayAccessibilityIdentifiers.addFundsButton
                    ),
                    FixedSizeButtonWithIconInfo(
                        title: Localization.tangempayCardDetailsWithdraw,
                        icon: Assets.arrowUpMini,
                        loading: viewModel.isWithdrawButtonLoading,
                        disabled: viewModel.actionButtonsDisabled,
                        action: viewModel.withdraw,
                        accessibilityIdentifier: TangemPayAccessibilityIdentifiers.withdrawButton
                    ),
                ]
            )
        }
        .padding(14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    // MARK: - Legacy single-card

    private var cardIconRow: some View {
        HStack(spacing: 8) {
            Button(action: viewModel.openCardManagement) {
                TangemPaySmallCardView(
                    state: viewModel.shouldDisplayReplacingCardBanner
                        ? .replacing
                        : .issued(cardNumberEnd: viewModel.cardNumberEnd)
                )
            }
            .disabled(viewModel.isStale)
            .opacity(viewModel.isStale ? 0.6 : 1)
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.paymentAccountCardButton)

            Button(action: viewModel.openFakedoorSheet) {
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

    // MARK: - Legacy multi-card

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
            .disabled(viewModel.addCardDisabled)
            .opacity(viewModel.addCardDisabled ? 0.6 : 1)

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
                TangemPaySmallCardView(state: viewModel.smallCardState(for: card))
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

    // MARK: - Redesign

    private var redesignedBody: some View {
        RefreshScrollView(stateObject: viewModel.refreshScrollViewStateObject, contentSettings: .simpleContent) {
            VStack(spacing: 0) {
                TangemElasticContainer(viewModel: elasticContainerModel, content: redesignedCollapsingHeader)
                    .opacity(redesignedHeaderOpacity)
                    .animation(.default, value: headerHeightRatio)

                redesignedTransactionList
                    .frame(maxWidth: .infinity, minHeight: visibleBodyHeight, alignment: .top)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background {
            DesignSystem.Color.bgPrimary
                .ignoresSafeArea()
        }
        .onReceive(elasticContainerModel.heightRatioPublisher) { headerHeightRatio = $0 }
        .onReceive(viewModel.refreshScrollViewStateObject.scrollViewInteractor.$visibleBodyHeight) { visibleBodyHeight = $0 }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .alert(item: $viewModel.alert) { $0.alert }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { redesignedToolbar }
        .modifyView { view in
            if #unavailable(iOS 26.0) {
                view.backportTranslucentNavigationBar()
            } else {
                view
            }
        }
        .redesigned()
    }

    private var redesignedHeaderOpacity: CGFloat {
        clamp(2 * headerHeightRatio - 1, min: 0, max: 1)
    }

    private var redesignedCollapsingHeader: some View {
        VStack(spacing: 28) {
            redesignedHeader

            if !viewModel.notificationBannerItems.isEmpty {
                NotificationBannerContainer(
                    items: viewModel.notificationBannerItems,
                    stackingType: .carousel
                )
            }

            if !viewModel.multipleCardsEnabled, viewModel.shouldDisplayReplacingCardBanner {
                TangemPayReplacingCardBanner()
            }

            if viewModel.shouldDisplayAddToApplePayGuide {
                redesignedAddToApplePayBanner
            }

            if viewModel.multipleCardsEnabled, viewModel.hasIssuingEntry {
                TangemPayIssuingCardBannerRedesigned()
            }

            ForEach(viewModel.pendingExpressTransactions) { transactionInfo in
                PendingExpressTransactionView(info: transactionInfo)
            }
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var redesignedTransactionList: some View {
        if !viewModel.isDeactivated {
            TransactionsListViewRedesigned(
                state: viewModel.tangemPayTransactionHistoryState,
                exploreAction: nil,
                exploreConfirmationDialog: nil,
                openTransactionDetailsAction: { viewModel.openTransactionDetails(id: $0.hash) },
                reloadButtonAction: viewModel.reloadHistory,
                isReloadButtonBusy: false,
                fetchMore: viewModel.fetchNextTransactionHistoryPage()
            )
        }
    }

    private var redesignedHeader: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                TangemPayBalanceView(state: viewModel.balance)
                    .opacity(viewModel.isStale ? 0.6 : 1)

                Text(Localization.tokenDetailsBalanceTotal)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textTertiary)
            }

            redesignedCardsRow

            TangemPayActionButtonsView(
                actionButtonsDisabled: viewModel.actionButtonsDisabled,
                isWithdrawDisabled: viewModel.isWithdrawButtonDisabled,
                addFundsAction: viewModel.addFunds,
                withdrawAction: viewModel.withdraw
            )
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    @ViewBuilder
    private var redesignedCardsRow: some View {
        HStack(spacing: 8) {
            if viewModel.multipleCardsEnabled {
                ForEach(viewModel.cardEntries) { entry in
                    redesignedCardEntryButton(for: entry)
                }

                Button(action: viewModel.tapAddCard) {
                    TangemPayAddCardView()
                }
                .disabled(viewModel.addCardDisabled)
                .opacity(viewModel.addCardDisabled ? 0.6 : 1)
            } else {
                Button(action: viewModel.openCardManagement) {
                    TangemPaySmallCardViewRedesigned(
                        state: viewModel.shouldDisplayReplacingCardBanner
                            ? .replacing
                            : .issued(cardNumberEnd: viewModel.cardNumberEnd)
                    )
                }
                .disabled(viewModel.isStale)
                .opacity(viewModel.isStale ? 0.6 : 1)
                .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.paymentAccountCardButton)

                Button(action: viewModel.openFakedoorSheet) {
                    TangemPayAddCardView()
                }
                .disabled(viewModel.isStale)
                .opacity(viewModel.isStale ? 0.6 : 1)
            }
        }
    }

    @ViewBuilder
    private func redesignedCardEntryButton(for entry: TangemPayCardEntry) -> some View {
        switch entry {
        case .issued(let card):
            Button {
                viewModel.openCardManagement(entry: entry)
            } label: {
                TangemPaySmallCardViewRedesigned(
                    state: card.isReissuing || card.isClosing
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
                TangemPaySmallCardViewRedesigned(state: .issuing)
            }
        }
    }

    private var redesignedAddToApplePayBanner: some View {
        TangemPayAddToApplePayBannerRedesigned(
            openAction: viewModel.openAddToApplePayGuide,
            closeAction: viewModel.dismissAddToApplePayGuideBanner
        )
    }

    @ToolbarContentBuilder
    private var redesignedToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 4) {
                Text(Localization.tangempayPaymentAccount)
                    .font(token: DesignSystem.Font.subheadingMediumToken)
                    .foregroundStyle(DesignSystem.Color.textPrimary)

                Text(Localization.tangempayUsdcOnPolygonNetwork)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textTertiary)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if FeatureProvider.isAvailable(.tangemPayTiers) {
                    Button(action: viewModel.openCurrentPlan) {
                        Label {
                            Text(Localization.tangempayCurrentPlanTitle)
                        } icon: {
                            DesignSystem.Icons.ArrowRefresh.regular20.image
                                .renderingMode(.template)
                        }
                    }

                    Divider()
                }

                Button(action: viewModel.termsAndLimits) {
                    Label(Localization.tangemPayTermsLimits, systemImage: "text.page")
                }

                Button(action: viewModel.contactSupport) {
                    Label(Localization.tangempayPaySupport, systemImage: "text.bubble")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Colors.Icon.primary1)
                    .accessibilityLabel(Localization.commonMore)
            }
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.moreActionsButton)
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
