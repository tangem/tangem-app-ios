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

    private let coordinateSpaceName = UUID()

    var body: some View {
        RefreshScrollView(stateObject: viewModel.refreshScrollViewStateObject) {
            VStack(spacing: 14) {
                TokenDetailsHeaderView(viewModel: viewModel.tokenDetailsHeaderModel)

                BalanceWithButtonsView(viewModel: viewModel.balanceWithButtonsModel)

                ForEach(viewModel.bannerNotificationInputs) { input in
                    NotificationView(input: input)
                }

                ForEach(viewModel.tokenNotificationInputs) { input in
                    NotificationView(input: input)
                        .setButtonsLoadingState(to: viewModel.isFulfillingAssetRequirements)
                }

                if viewModel.isMarketsDetailsAvailable {
                    MarketPriceView(
                        currencySymbol: viewModel.currencySymbol,
                        price: viewModel.rateFormatted,
                        priceChangeState: viewModel.priceChangeState,
                        miniChartData: viewModel.miniChartData,
                        tapAction: viewModel.openMarketsTokenDetails
                    )
                }

                yieldStatusView

                if let activeStakingViewData = viewModel.activeStakingViewData {
                    ActiveStakingView(data: activeStakingViewData)
                        .padding(14)
                        .background(Colors.Background.primary)
                        .cornerRadiusContinuous(14)
                }

                ForEach(viewModel.pendingExpressTransactions) { transactionInfo in
                    PendingExpressTransactionView(info: transactionInfo)
                }

                PendingTransactionsListView(
                    items: viewModel.pendingTransactionViews,
                    exploreTransactionAction: viewModel.openTransactionExplorer
                )

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
            .padding(.top, Constants.headerTopPadding)
            .readContentOffset(
                inCoordinateSpace: .named(coordinateSpaceName),
                bindTo: scrollOffsetHandler.contentOffsetSubject.asWriteOnlyBinding(.zero)
            )
        }
        .padding(.horizontal, 16)
        .edgesIgnoringSafeArea(.bottom)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: viewModel.onAppear)
        .onAppear(perform: scrollOffsetHandler.onViewAppear)
        .alert(item: $viewModel.alert) { $0.alert }
        .coordinateSpace(name: coordinateSpaceName)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
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

            ToolbarItem(placement: .navigationBarTrailing) {
                navbarTrailingButton
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier(TokenAccessibilityIdentifiers.moreButton)
            }
        })
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var navbarTrailingButton: some View {
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
}

// MARK: - Constants

private extension TokenDetailsView {
    enum Constants {
        static let tokenIconSizeSettings: IconViewSizeSettings = .tokenDetails
        static let headerTopPadding: CGFloat = 14.0
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
    let apiProviderFactory = ExpressAPIProviderFactory()
    let expressAPIProviderResolver = ExpressAPIProviderResolver(
        providerFactory: { userWalletId, refcode in
            apiProviderFactory.makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
        }
    )
    let pendingExpressTxsManager = CommonPendingExpressTransactionsManager(
        userWalletId: userWalletModel.userWalletId.stringValue,
        tokenItem: walletModel.tokenItem,
        walletModelUpdater: walletModel,
        expressAPIProviderResolver: expressAPIProviderResolver,
        expressRefundedTokenHandler: ExpressRefundedTokenHandlerMock()
    )
    let pendingOnrampTxsManager = CommonPendingOnrampTransactionsManager(
        userWalletId: userWalletModel.userWalletId.stringValue,
        tokenItem: walletModel.tokenItem,
        expressAPIProvider: expressAPIProviderResolver.provider(for: userWalletModel.userWalletId.stringValue, refcode: userWalletModel.refcodeProvider?.getRefcode())
    )
    let pendingTxsManager = CompoundPendingTransactionsManager(
        swapManager: pendingExpressTxsManager,
        onrampManager: pendingOnrampTxsManager
    )
    let coordinator = TokenDetailsCoordinator()

    let bannerNotificationManager = BannerNotificationManager(
        userWalletInfo: userWalletModel.userWalletInfo,
        placement: .tokenDetails(walletModel.tokenItem),
    )

    TokenDetailsView(viewModel: .init(
        userWalletInfo: userWalletModel.userWalletInfo,
        walletModel: walletModel,
        notificationManager: notifManager,
        bannerNotificationManager: bannerNotificationManager,
        userTokensManager: cryptoAccountModel.userTokensManager,
        pendingExpressTransactionsManager: pendingTxsManager,
        xpubGenerator: nil,
        coordinator: coordinator,
        tokenRouter: SingleTokenRouter(
            userWalletInfo: userWalletModel.userWalletInfo,
            coordinator: coordinator
        ),
        pendingTransactionDetails: nil
    ))
}
