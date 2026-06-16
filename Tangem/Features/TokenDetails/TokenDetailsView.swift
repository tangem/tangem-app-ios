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
                if !viewModel.isRedesign {
                    TokenDetailsHeaderView(viewModel: viewModel.tokenDetailsHeaderModel)
                }

                if viewModel.isRedesign {
                    TokenDetailsBalanceView(viewModel: viewModel.balanceViewModel)
                        .padding(.vertical, max(0, .unit(.x10) - Constants.sectionSpacing))

                    if viewModel.isZeroBalance {
                        VStack(spacing: .unit(.x2)) {
                            redesignNotificationBanners
                            redesignYieldView
                            redesignStakingView
                        }
                    }

                    if let actionsViewModel = viewModel.actionsViewModel {
                        TokenDetailsActionsView(viewModel: actionsViewModel)
                    }
                } else {
                    BalanceWithButtonsView(viewModel: viewModel.balanceWithButtonsModel)
                }

                notifications

                marketPriceLegacy

                yieldView

                stakingView

                ForEach(viewModel.pendingExpressTransactions) { transactionInfo in
                    PendingExpressTransactionView(info: transactionInfo)
                }

                PendingTransactionsListView(
                    items: viewModel.pendingTransactionViews,
                    exploreTransactionAction: viewModel.openTransactionExplorer
                )

                if let quickTopUpVM = viewModel.quickTopUpBannerViewModel {
                    QuickTopUpBannerView(viewModel: quickTopUpVM)
                }

                if FeatureProvider.isAvailable(.redesign) {
                    TransactionsListViewRedesigned(
                        state: viewModel.transactionHistoryState,
                        exploreAction: viewModel.openExplorer,
                        exploreConfirmationDialog: $viewModel.exploreConfirmationDialog,
                        exploreTransactionAction: viewModel.openTransactionExplorer,
                        reloadButtonAction: viewModel.onButtonReloadHistory,
                        isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                        fetchMore: viewModel.fetchMoreHistory()
                    )
                    .padding(.bottom, 40)
                } else {
                    // [REDACTED_INFO]: remove legacy transactions list after redesign rollout.
                    TransactionsListView(
                        state: viewModel.transactionHistoryState,
                        exploreAction: viewModel.openExplorer,
                        exploreConfirmationDialog: $viewModel.exploreConfirmationDialog,
                        exploreTransactionAction: viewModel.openTransactionExplorer,
                        reloadButtonAction: viewModel.onButtonReloadHistory,
                        isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                        fetchMore: viewModel.fetchMoreHistory()
                    )
                    .padding(.bottom, 40)
                }
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
        .onFirstAppear {
            viewModel.onFirstAppear()
        }
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            marketPriceRedesign
        }
        .ignoresSafeArea(.keyboard)
        .alert(item: $viewModel.alert) { $0.alert }
        .coordinateSpace(name: CoordinateSpaceName.scrollView)
        .toolbar {
            principalToolbarContent
            trailingToolbarButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .modifyView { view in
            if #unavailable(iOS 26.0), viewModel.isRedesign {
                view.backportTranslucentNavigationBar()
            } else {
                view
            }
        }
    }

    @ToolbarContentBuilder
    private var principalToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            if viewModel.isRedesign {
                redesignPrincipalToolbarContent
            } else {
                legacyPrincipalToolbarContent
            }
        }
    }

    private var redesignPrincipalToolbarContent: some View {
        TokenDetailsNavigationBar(viewModel: viewModel.navigationBarViewModel)
    }

    private var legacyPrincipalToolbarContent: some View {
        TokenIcon(
            tokenIconInfo: .init(
                name: "",
                blockchainIconAsset: nil,
                imageURL: viewModel.iconUrl,
                isCustom: false,
                customTokenColor: viewModel.customTokenColor
            ),
            size: IconViewSizeSettings.tokenDetailsToolbar.iconSize
        )
        .opacity(scrollOffsetHandler.state)
    }

    private var trailingToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Group {
                if viewModel.isRedesign {
                    redesignTrailingToolbarButton
                } else {
                    legacyTrailingToolbarButton
                }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(TokenAccessibilityIdentifiers.moreButton)
        }
    }

    @ViewBuilder
    private var legacyTrailingToolbarButton: some View {
        if !viewModel.dotsMenuItems.isEmpty {
            Menu {
                ForEach(indexed: viewModel.dotsMenuItems.indexed()) { _, item in
                    Button(item.type.title, role: item.type.role, action: item.action)
                        .accessibilityIdentifier(item.type.accessibilityIdentifier)
                }
            } label: {
                NavbarDotsImage()
            }
        }
    }

    @ViewBuilder
    private var yieldView: some View {
        if viewModel.isRedesign, !viewModel.isZeroBalance {
            redesignYieldView
        } else {
            yieldStatusView
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
    private var stakingView: some View {
        if viewModel.isRedesign, !viewModel.isZeroBalance {
            redesignStakingView
        } else {
            legacyStakingView
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
    private var legacyStakingView: some View {
        if let activeStakingViewData = viewModel.activeStakingViewData {
            ActiveStakingView(data: activeStakingViewData)
                .padding(14)
                .background(Colors.Background.primary)
                .cornerRadiusContinuous(14)
        }
    }

    @ViewBuilder
    private var redesignTrailingToolbarButton: some View {
        if !viewModel.dotsMenuItems.isEmpty {
            Menu("", systemImage: "ellipsis") {
                ForEach(viewModel.dotsMenuItems) { menuItem in
                    Button(menuItem.type.title, role: menuItem.type.role, action: menuItem.action)
                        .accessibilityIdentifier(menuItem.type.accessibilityIdentifier)
                }
            }
        }
    }

    @ViewBuilder
    private var notifications: some View {
        if viewModel.isRedesign, !viewModel.isZeroBalance {
            redesignNotificationBanners
        } else {
            ForEach(viewModel.tokenNotificationInputs) { input in
                NotificationView(input: input)
                    .setButtonsLoadingState(to: viewModel.isFulfillingAssetRequirements)
            }
        }
    }

    private var redesignNotificationBanners: some View {
        VStack(spacing: .unit(.x2)) {
            ForEach(viewModel.notifications) { notification in
                NotificationBanner(
                    bannerType: notification.bannerType,
                    accessibilityIdentifier: notification.accessibilityIdentifier
                )
            }
        }
    }

    @ViewBuilder
    private var marketPriceLegacy: some View {
        if !viewModel.isRedesign, viewModel.isMarketsDetailsAvailable {
            MarketPriceView(
                currencySymbol: viewModel.currencySymbol,
                price: viewModel.rateFormatted,
                priceChangeState: viewModel.priceChangeState,
                miniChartData: viewModel.miniChartData,
                tapAction: viewModel.openMarketsTokenDetails
            )
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

    @ViewBuilder
    private var yieldStatusView: some View {
        switch viewModel.yieldModuleAvailability {
        case .checking, .notApplicable:
            EmptyView()

        case .eligible(let vm):
            YieldAvailableNotificationView(viewModel: vm)

        case .enter(let vm), .exit(let vm), .active(let vm):
            YieldStatusView(viewModel: vm)
        }
    }

    private var backgroundColor: Color {
        viewModel.isRedesign
            ? Color.Tangem.Surface.level2
            : Colors.Background.secondary
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

#Preview {
    let userWalletModel = FakeUserWalletModel.wallet3Cards
    let cryptoAccountModel = userWalletModel
        .accountModelsManager
        .cryptoAccountModels[0]

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
    let pendingExpressTxsManager = CommonPendingExpressTransactionsManager(
        userWalletId: userWalletModel.userWalletId.stringValue,
        tokenItem: walletModel.tokenItem,
        walletModelUpdater: walletModel,
        cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory,
        expressRefundedTokenHandler: ExpressRefundedTokenHandlerMock()
    )
    let onrampExpressAPIProvider = cachingExpressAPIProviderFactory.provider(for: userWalletModel.userWalletId.stringValue, refcode: userWalletModel.refcodeProvider?.getRefcode())
    let pendingOnrampTxsManager = CommonPendingOnrampTransactionsManager(
        userWalletId: userWalletModel.userWalletId.stringValue,
        tokenItem: walletModel.tokenItem,
        expressAPIProvider: onrampExpressAPIProvider,
        unknownStatusRecoveryService: CommonOnrampUnknownStatusRecoveryService(
            userWalletId: userWalletModel.userWalletId.stringValue,
            tokenItem: walletModel.tokenItem,
            expressAPIProvider: onrampExpressAPIProvider
        )
    )
    let pendingTxsManager = CompoundPendingTransactionsManager(
        first: pendingExpressTxsManager,
        second: pendingOnrampTxsManager
    )
    let coordinator = TokenDetailsCoordinator()

    TokenDetailsView(
        viewModel: .init(
            userWalletInfo: userWalletModel.userWalletInfo,
            walletModel: walletModel,
            notificationManager: notifManager,
            userTokensManager: cryptoAccountModel.userTokensManager,
            pendingExpressTransactionsManager: pendingTxsManager,
            xpubGenerator: nil,
            coordinator: coordinator,
            tokenRouter: SingleTokenRouter(
                userWalletInfo: userWalletModel.userWalletInfo,
                coordinator: coordinator
            ),
            pendingTransactionDetails: nil
        )
    )
}
