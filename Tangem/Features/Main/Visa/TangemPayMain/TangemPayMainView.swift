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

            if viewModel.shouldDisplayAddToApplePayGuide {
                redesignedAddToApplePayBanner
            }

            if viewModel.hasIssuingEntry, !viewModel.isAwaitingDeposit {
                TangemPayIssuingCardBannerRedesigned()
            }

            if viewModel.isAwaitingDeposit {
                awaitingDepositCancelBanner
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
                exploreTransactionAction: viewModel.openTransactionDetails,
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
                isWithdrawDisabled: viewModel.isWithdrawButtonDisabled,
                addFundsAction: viewModel.addFunds,
                withdrawAction: viewModel.withdraw
            )
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    // [REDACTED_TODO_COMMENT]
    private var awaitingDepositCancelBanner: some View {
        let title = viewModel.awaitingDepositMonthlyFee
            .map { "Top-up your account on \($0)" } ?? "Top-up your account"

        return NotificationBanner(
            bannerType: .warning(
                .textWithIcon(
                    .init(
                        text: .init(
                            title: AttributedString(title),
                            subtitle: AttributedString("To pay monthly fee for plan and start use card")
                        ),
                        icon: .init(imageType: Assets.attention)
                    )
                ),
                .buttons(.one(
                    .init(
                        content: .text(AttributedString("Cancel Plus, move to Basic")),
                        styleType: .primary,
                        cornerStyle: .rounded,
                        action: { [viewModel] in
                            Task { @MainActor in viewModel.cancelPlus() }
                        }
                    ),
                    accessibilityIdentifier: nil
                ))
            ),
            accessibilityIdentifier: nil
        )
    }

    // [REDACTED_TODO_COMMENT]
    private var inactiveBadge: some View {
        TangemBadgeV2(label: "Inactive", accessibilityLabel: nil)
            .size(.x6)
            .variant(.tinted)
            .appearance(.warning)
            .slotStart(DesignSystem.Icons.Info.regular16)
    }

    @ViewBuilder
    private var redesignedCardsRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.cardEntries) { entry in
                redesignedCardEntryButton(for: entry)
            }

            Button(action: viewModel.tapAddCard) {
                TangemPayAddCardView()
            }
            .disabled(viewModel.addCardDisabled)
            .opacity(viewModel.addCardDisabled ? 0.6 : 1)
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
                        : .issued(cardNumberEnd: card.cardNumberEnd, isFrozen: card.isFrozen)
                )
            }
            .accessibilityIdentifier(TangemPayAccessibilityIdentifiers.paymentAccountCardButton(cardId: card.cardId))
            .disabled(viewModel.isStale)
            .opacity(viewModel.isStale ? 0.6 : 1)
        case .issuing:
            Button {
                viewModel.openCardManagement(entry: entry)
            } label: {
                TangemPaySmallCardViewRedesigned(
                    state: entry.order?.isAwaitingDeposit == true ? .ghost : .issuing
                )
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
                        Text(Localization.tangempayCurrentPlanTitle)

                        switch viewModel.currentPlanState {
                        case .plan(let name):
                            Text(name)
                        case .changing:
                            // [REDACTED_TODO_COMMENT]
                            Text("changing your plan")
                        case .unknown:
                            EmptyView()
                        }

                        DesignSystem.Icons.Info.regular20.image
                            .renderingMode(.template)
                    }
                    .disabled(viewModel.currentPlanState == .changing)

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
