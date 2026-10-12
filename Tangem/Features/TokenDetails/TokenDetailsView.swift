//
//  TokenDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct TokenDetailsView: View {
    @ObservedObject var viewModel: TokenDetailsViewModel

    @StateObject private var scrollOffsetHandler = ScrollViewOffsetHandler.tokenDetails(
        tokenIconSizeSettings: Constants.tokenIconSizeSettings,
        headerTopPadding: Constants.headerTopPadding
    )

    var body: some View {
        // This scroll view must use non-lazy content settings because the transactions list view
        // and other subviews already contain inner lazy stacks.
        // Nested lazy stacks are known to cause various issues with scroll offset handling and content rendering.
        RefreshScrollView(stateObject: viewModel.refreshScrollViewStateObject, contentSettings: .simpleContent) {
            VStack(spacing: Constants.sectionSpacing) {
                TokenDetailsBalanceView(viewModel: viewModel.balanceViewModel)
                    .padding(.vertical, max(0, .unit(.x10) - Constants.sectionSpacing))

                redesignActionsSection

                marketingBanner

                PendingTransactionsListView(
                    items: viewModel.pendingTransactionViews,
                    exploreTransactionAction: viewModel.openTransactionExplorer
                )

                VStack(spacing: .zero) {
                    if let jointOperationsSection = viewModel.jointOperationsInFlightSection {
                        TransactionsListSectionView(
                            item: jointOperationsSection,
                            openTransactionDetailsAction: viewModel.openTransactionDetails
                        )
                    }

                    TransactionsListViewRedesigned(
                        state: viewModel.transactionHistoryState,
                        exploreAction: viewModel.openExplorer,
                        openTransactionDetailsAction: viewModel.openTransactionDetails,
                        reloadButtonAction: viewModel.onButtonReloadHistory,
                        isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                        fetchMore: viewModel.fetchMoreHistory()
                    )
                }
                .padding(.bottom, 40)
            }
            .padding(.top, Constants.headerTopPadding)
            .readContentOffset(
                inCoordinateSpace: .named(CoordinateSpaceName.scrollView),
                bindTo: scrollOffsetHandler.contentOffsetSubject.asWriteOnlyBinding(.zero)
            )
        }
        .padding(.horizontal, 16)
        .background {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            viewModel.onAppear()
            scrollOffsetHandler.onViewAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onFirstAppear {
            viewModel.onFirstAppear()
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            marketPriceRedesign
        }
        .ignoresSafeArea(.keyboard)
        .alert(item: $viewModel.alert) { $0.alert }
        .confirmationDialog(viewModel: $viewModel.exploreConfirmationDialog)
        .coordinateSpace(name: CoordinateSpaceName.scrollView)
        .modifier(NavigationModifier(
            presentSource: viewModel.presentSource,
            backgroundColor: backgroundColor,
            leadingContent: { leadingContent },
            principalContent: { principalContent },
            trailingContent: { trailingContent }
        ))
    }

    private var leadingContent: some View {
        NavigationBarButton.back(action: viewModel.onBack)
            .redesigned()
    }

    @ViewBuilder
    private var principalContent: some View {
        redesignPrincipalToolbarContent
    }

    private var redesignPrincipalToolbarContent: some View {
        TokenDetailsNavigationBar(viewModel: viewModel.navigationBarViewModel)
    }

    private var trailingContent: some View {
        Group {
            redesignTrailingToolbarButton
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Localization.commonMore)
        .accessibilityIdentifier(TokenAccessibilityIdentifiers.moreButton)
    }

    @ViewBuilder
    private var redesignActionsSection: some View {
        if let actionsViewModel = viewModel.actionsViewModel {
            TokenDetailsRedesignActionsSection(actionsViewModel: actionsViewModel) {
                redesignBanners
            } quickTopUp: {
                quickTopUpBanner
            }
        }
    }

    private var redesignBanners: some View {
        VStack(spacing: .unit(.x2)) {
            redesignNotificationBanners
            redesignYieldView
            redesignStakingView
        }
    }

    @ViewBuilder
    private var quickTopUpBanner: some View {
        if let quickTopUpVM = viewModel.quickTopUpBannerViewModel {
            QuickTopUpBannerView(viewModel: quickTopUpVM)
        }
    }

    @ViewBuilder
    private var redesignYieldView: some View {
        switch viewModel.yieldState {
        case .some(let state):
            TokenDetailsYieldView(state: state)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var redesignStakingView: some View {
        switch viewModel.stakingState {
        case .some(let state):
            TokenDetailsStakingView(state: state)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var redesignTrailingToolbarButton: some View {
        if !viewModel.dotsMenuSections.isEmpty {
            switch viewModel.presentSource {
            case .navigation:
                Menu {
                    dotsMenuContent
                } label: {
                    DesignSystem.Icons.DotsHorizontal.regular24.image
                        .renderingMode(.template)
                }
            case .markets:
                Menu(
                    content: {
                        dotsMenuContent
                    },
                    label: {
                        NavigationBarButton.details(action: {})
                            .redesigned()
                            .allowsHitTesting(false)
                    }
                )
            }
        }
    }

    private var dotsMenuContent: some View {
        ForEach(viewModel.dotsMenuSections) { section in
            Section {
                ForEach(section.items) { menuItem in
                    SwiftUI.Button(role: menuItem.type.role, action: menuItem.action) {
                        Label(
                            title: { Text(menuItem.type.title) },
                            icon: { menuItem.type.icon.image.renderingMode(.template) }
                        )
                    }
                    .accessibilityIdentifier(menuItem.type.accessibilityIdentifier)
                }
            }
        }
    }

    private var redesignNotificationBanners: some View {
        VStack(spacing: .unit(.x2)) {
            ForEach(viewModel.notifications) { notification in
                NotificationMessageBanner(
                    bannerType: notification.bannerType,
                    variant: notification.variant,
                    ring: notification.ring,
                    textColors: notification.textColors,
                    accessibilityIdentifier: notification.accessibilityIdentifier
                )
            }
        }
    }

    @ViewBuilder
    private var marketingBanner: some View {
        if let standaloneMarketingBanners = viewModel.standaloneMarketingBanners {
            StandaloneMarketingBannersView(banners: standaloneMarketingBanners)
        }
    }

    @ViewBuilder
    private var marketPriceRedesign: some View {
        if let viewModel = viewModel.marketPriceViewModel {
            TokenDetailsMarketPriceView(viewModel: viewModel)
                .padding(.horizontal, .unit(.x4))
                .padding(.vertical, .unit(.x2))
                .background {
                    LinearGradient.Tangem.Common.tokenDetailsMarketPrice
                        .ignoresSafeArea()
                }
        }
    }

    private var backgroundColor: Color {
        Color.Tangem.Surface.level2
    }
}

// MARK: - Constants

extension TokenDetailsView {
    enum Constants {
        static let tokenIconSizeSettings: IconViewSizeSettings = .tokenDetails
        static let headerTopPadding: CGFloat = 14.0
        static let sectionSpacing: CGFloat = 14
    }
}

private extension TokenDetailsView {
    enum CoordinateSpaceName {
        private static let prefix = "TokenDetailsView.CoordinateSpaceName."

        static let scrollView = prefix + "scrollView"
    }
}

// MARK: - Navigation modifier

private extension TokenDetailsView {
    struct NavigationModifier<LeadingContent, PrincipalContent, TrailingContent>: ViewModifier
        where LeadingContent: View, PrincipalContent: View, TrailingContent: View {
        let presentSource: TokenDetailsPresentSource
        let backgroundColor: Color

        @ViewBuilder var leadingContent: LeadingContent
        @ViewBuilder var principalContent: PrincipalContent
        @ViewBuilder var trailingContent: TrailingContent

        func body(content: Content) -> some View {
            Group {
                switch presentSource {
                case .navigation: makeCommonNavigation(content: content)
                case .markets: makeMarketsNavigation(content: content)
                }
            }
            .translucentNavigationBar()
        }

        private func makeCommonNavigation(content: Content) -> some View {
            content
                .toolbar {
                    ToolbarItem(placement: .principal) { principalContent }
                    ToolbarItem(placement: .topBarTrailing) { trailingContent }
                }
                .navigationBarTitleDisplayMode(.inline)
        }

        private func makeMarketsNavigation(content: Content) -> some View {
            content
                .safeAreaInset(edge: .top, spacing: 16) {
                    NavigationHeader(
                        leadingContent: { leadingContent },
                        principalContent: { principalContent },
                        trailingContent: { trailingContent }
                    )
                    .backgroundColor(backgroundColor)
                    .contentShape(.rect)
                }
        }
    }
}

// MARK: - Previews

#Preview {
    let userWalletModel = FakeUserWalletModel.wallet3Cards
    let cryptoAccountModel = AccountModelsAggregator(.crypto, .joint)
        .models(from: userWalletModel.accountModelsManager)[0]

    let walletModel = cryptoAccountModel
        .walletModelsManager
        .walletModels
        .first ?? CommonWalletModel.mockETH

    let notifManager = SingleTokenNotificationManager(
        userWalletId: userWalletModel.userWalletId,
        walletModel: walletModel,
        walletModelsManager: cryptoAccountModel.walletModelsManager,
        tangemIconProvider: CommonTangemIconProvider(hasNFCInteraction: true)
    )
    let cachingExpressAPIProviderFactory = CachingExpressAPIProviderFactory { userWalletId, refcode in
        ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
    }
    let exchangeStatusPoller = ExchangeStatusPoller(
        userWalletId: userWalletModel.userWalletId,
        tokenItem: walletModel.tokenItem,
        cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory,
        expressRefundedTokenHandler: ExpressRefundedTokenHandlerMock()
    )
    let pendingExpressTxsManager = CommonPendingExpressTransactionsManager(poller: exchangeStatusPoller)
    let onrampExpressAPIProvider = cachingExpressAPIProviderFactory.provider(for: userWalletModel.userWalletId.stringValue, refcode: userWalletModel.refcodeProvider?.getRefcode())
    let onrampStatusPoller = OnrampStatusPoller(
        userWalletId: userWalletModel.userWalletId,
        tokenItem: walletModel.tokenItem,
        expressAPIProvider: onrampExpressAPIProvider
    )
    let unknownStatusRecoveryService = CommonOnrampUnknownStatusRecoveryService(
        userWalletId: userWalletModel.userWalletId,
        tokenItem: walletModel.tokenItem,
        expressAPIProvider: onrampExpressAPIProvider
    )
    let pendingOnrampTxsManager = CommonPendingOnrampTransactionsManager(
        unknownStatusRecoveryService: unknownStatusRecoveryService,
        poller: onrampStatusPoller
    )
    let pendingTxsManager = CompoundPendingTransactionsManager(
        first: pendingExpressTxsManager,
        second: pendingOnrampTxsManager
    )
    let coordinator = TokenDetailsCoordinator()
    let expressStatusPollingHelper = ExpressStatusPollingHelper(
        exchangePoller: exchangeStatusPoller,
        onrampPoller: onrampStatusPoller,
        enricherFactory: { nil }
    )

    TokenDetailsView(
        viewModel: .init(
            userWalletInfo: userWalletModel.userWalletInfo,
            walletModel: walletModel,
            notificationManager: notifManager,
            userTokensManager: cryptoAccountModel.userTokensManager,
            addressBookManager: userWalletModel.addressBookManager,
            pendingExpressTransactionsManager: pendingTxsManager,
            expressStatusPollingHelper: expressStatusPollingHelper,
            xpubGenerator: nil,
            coordinator: coordinator,
            tokenRouter: SingleTokenRouter(
                userWalletInfo: userWalletModel.userWalletInfo,
                analyticsSource: .token,
                coordinator: coordinator
            ),
            pendingTransactionDetails: nil,
            deeplinkHandler: TokenScreenDeeplinkResponder(
                coordinator: coordinator,
                walletModel: walletModel,
                userWalletInfo: userWalletModel.userWalletInfo
            ),
            presentSource: .navigation
        )
    )
}
