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

    @StateObject private var elasticContainerModel: TangemElasticContainerModel
    @State private var headerHeightRatio: CGFloat = 1
    @State private var visibleBodyHeight: CGFloat = 0
    @State private var cardsRowWidth: CGFloat = 0

    init(viewModel: TangemPayMainViewModel) {
        self.viewModel = viewModel
        _elasticContainerModel = StateObject(
            wrappedValue: TangemElasticContainerModel(
                scrollViewInteractor: viewModel.refreshScrollViewStateObject.scrollViewInteractor
            )
        )
    }

    var body: some View {
        redesignedBody
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

            VStack(spacing: 8) {
                PromotionNotificationsView(viewModel: viewModel.promotionNotificationsViewModel)

                if !viewModel.notificationBannerItems.isEmpty {
                    NotificationBannerContainer(
                        items: viewModel.notificationBannerItems,
                        stackingType: .carousel
                    )
                }

                if viewModel.shouldDisplayAddToApplePayGuide {
                    redesignedAddToApplePayBanner
                }

                if let contactSupportButton = viewModel.contactSupportMessageBannerButton {
                    failedToIssueCardBanner(contactSupportButton: contactSupportButton)
                }

                if viewModel.hasIssuingEntry, !viewModel.isAwaitingDeposit {
                    TangemPayIssuingCardBannerRedesigned()
                }

                if let banner = viewModel.systemDowngradeBanner {
                    MessageBanner(title: banner.title, description: banner.subtitle)
                        .variant(.error)
                        .glowRing(.error)
                        .primaryButton(
                            .init(title: Localization.tangempayCardDetailsAddFunds, action: viewModel.addFunds)
                        )
                        .onAppear(perform: viewModel.onSystemDowngradeBannerAppear)
                }

                if let fee = viewModel.awaitingDepositInfo?.fee {
                    awaitingDepositTopUpBanner(fee: fee)
                        .onAppear(perform: viewModel.onTopupBannerAppear)
                }

                cashbackSection
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
                TangemPayBalanceView(state: viewModel.balance, isError: viewModel.isBalanceNegative)
                    .opacity(viewModel.isStale ? 0.6 : 1)

                if viewModel.isAwaitingDeposit {
                    inactiveBadge
                } else {
                    Text(Localization.tokenDetailsBalanceTotal)
                        .font(token: DesignSystem.Font.captionMediumToken)
                        .foregroundStyle(DesignSystem.Color.textTertiary)
                }
            }

            redesignedCardsRow

            TangemPayActionButtonsView(
                actionButtonsDisabled: viewModel.actionButtonsDisabled,
                isAddFundsDisabled: viewModel.isAddFundsButtonDisabled,
                isWithdrawDisabled: viewModel.isWithdrawButtonDisabled,
                addFundsAction: viewModel.addFunds,
                withdrawAction: viewModel.withdraw
            )
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    private func awaitingDepositTopUpBanner(fee: String) -> some View {
        MessageBanner(
            title: Localization.tangempayCardDetailsAwaitingDepositTitle(fee),
            description: Localization.tangempayCardDetailsAwaitingDepositSubtitle
        )
        .variant(.error)
        .slotEnd {
            Assets.DesignSystem.warning.image
                .renderingMode(.template)
                .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)
        }
        .primaryButton(viewModel.awaitingDepositAddFundsButton)
    }

    private func failedToIssueCardBanner(contactSupportButton: MessageBannerButton) -> some View {
        MessageBanner(
            title: Localization.tangempayFailedToIssueCard,
            description: Localization.tangempayFailedToIssueCardSupportDescription
        )
        .variant(.error)
        .slotStart {
            DesignSystem.Icons.Error.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
        .primaryButton(contactSupportButton)
    }

    private var inactiveBadge: some View {
        Badge(label: Localization.tangempayStatusInactive, accessibilityLabel: nil)
            .size(.x6)
            .variant(.tinted)
            .appearance(.warning)
            .slotStart(DesignSystem.Icons.Info.regular16)
    }

    private var redesignedCardsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.cardEntries) { entry in
                    redesignedCardEntryButton(for: entry)
                }

                SwiftUI.Button(action: viewModel.tapAddCard) {
                    TangemPayAddCardView()
                }
                .disabled(viewModel.addCardDisabled)
                .opacity(viewModel.addCardDisabled ? 0.6 : 1)
            }
            .padding(.horizontal, 16)
            .frame(minWidth: cardsRowWidth)
        }
        // cardsRowWidth logic is needed to preserve center alignment, on iOS 17+ can be replaced with containerRelativeFrame
        .readGeometry(\.size.width, bindTo: $cardsRowWidth)
    }

    @ViewBuilder
    private func redesignedCardEntryButton(for entry: TangemPayCardEntry) -> some View {
        switch entry {
        case .issued(let card):
            SwiftUI.Button {
                viewModel.openCardManagement(entry: entry)
            } label: {
                TangemPaySmallCardViewRedesigned(
                    state: card.isReissuing || card.isClosing
                        ? .replacing
                        : .issued(cardNumberEnd: card.cardNumberEnd, isFrozen: card.isFrozen, thumbnailURL: card.thumbnailImageURL)
                )
            }
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.paymentAccountCardButton(cardId: card.cardId))
            .disabled(viewModel.isStale)
            .opacity(viewModel.isStale ? 0.6 : 1)
        case .issuing:
            SwiftUI.Button {
                viewModel.openCardManagement(entry: entry)
            } label: {
                TangemPaySmallCardViewRedesigned(state: entry.isGhost ? .ghost : .issuing)
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

                Text(viewModel.toolbarSubtitle)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textTertiary)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                SwiftUI.Button(action: viewModel.openCurrentPlan) {
                    Text(Localization.tangempayCurrentPlanTitle)

                    switch viewModel.currentPlanState {
                    case .plan(let name):
                        Text(name)

                        DesignSystem.Icons.Info.regular20.image
                            .renderingMode(.template)
                    case .changing:
                        Text(Localization.tangempayChangingPlan)

                        DesignSystem.Icons.ArrowRefresh.regular20.image
                            .renderingMode(.template)
                    case .unknown:
                        DesignSystem.Icons.Info.regular20.image
                            .renderingMode(.template)
                    }
                }

                Divider()

                if let cashbackMenuState = viewModel.cashbackMenuState {
                    SwiftUI.Button(action: viewModel.onCashbackMenuItemTap) {
                        Text(cashbackMenuState.menuTitle)

                        if let menuSubtitle = cashbackMenuState.menuSubtitle {
                            Text(menuSubtitle)
                        }

                        DesignSystem.Icons.PercentBackward.regular20.image
                            .renderingMode(.template)
                    }
                    .menuActionDismissBehavior(.disabled)
                    .disabled(cashbackMenuState.isReloading)
                    .onAppear(perform: viewModel.logCashbackMenuItemImpression)
                    .onChange(of: viewModel.cashbackMenuItemImpression) { _ in
                        viewModel.logCashbackMenuItemImpression()
                    }
                }

                if viewModel.isVisaBenefitsAvailable {
                    SwiftUI.Button(action: viewModel.visaBenefits) {
                        Label {
                            Text(Localization.tangempayVisaBenefits)
                        } icon: {
                            DesignSystem.Icons.Heart.regular20.image
                        }
                    }
                }

                SwiftUI.Button(action: viewModel.termsAndLimits) {
                    Label(Localization.tangemPayTermsLimits, systemImage: "text.page")
                }

                SwiftUI.Button(action: viewModel.contactSupport) {
                    Label(Localization.tangempayPaySupport, systemImage: "text.bubble")
                }

                if viewModel.isDeactivated {
                    SwiftUI.Button(role: .destructive, action: viewModel.promptRemoveAccount) {
                        Label(Localization.tangempayRemoveAccount, systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Colors.Icon.primary1)
                    .accessibilityLabel(Localization.commonMore)
            }
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.moreActionsButton)
        }
    }

    @ViewBuilder
    private var cashbackSection: some View {
        if let cashbackBannerState = viewModel.cashbackBannerState {
            TangemPayCashbackBanner(state: cashbackBannerState, action: viewModel.onCashbackBannerTap)
                .onAppear(perform: viewModel.logCashbackBannerImpression)
                .onChange(of: viewModel.cashbackBannerImpression) { _ in
                    viewModel.logCashbackBannerImpression()
                }
        } else if let gotItButton = viewModel.cashbackBlockedBanner {
            cashbackBlockedBanner(gotItButton: gotItButton)
                .onAppear(perform: viewModel.onCashbackBlockedBannerAppear)
        }
    }

    private func cashbackBlockedBanner(gotItButton: MessageBannerButton) -> some View {
        MessageBanner(
            title: Localization.tangempayCashbackDeactivatedTitle,
            description: Localization.tangempayCashbackDeactivatedDescription
        )
        .glowRing(.error)
        .slotEnd {
            DesignSystem.Icons.Error.regular20.image
                .renderingMode(.template)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
        }
        .secondaryButton(gotItButton)
    }
}
