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
        .confirmationDialog(viewModel: $viewModel.confirmationDialog)
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
        if viewModel.hasDotsMenu {
            Menu {
                if viewModel.canGenerateXPUB {
                    Button(Localization.tokenDetailsGenerateXpub, action: viewModel.generateXPUBButtonAction)
                }

                if viewModel.canHideToken {
                    Button(Localization.tokenDetailsHideToken, role: .destructive, action: viewModel.hideTokenButtonAction)
                        .accessibilityIdentifier(TokenAccessibilityIdentifiers.hideTokenButton)
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
    let walletModel = userWalletModel.walletModelsManager.walletModels.first ?? CommonWalletModel.mockETH

    let notifManager = SingleTokenNotificationManager(
        userWalletId: userWalletModel.userWalletId,
        walletModel: walletModel,
        walletModelsManager: userWalletModel.walletModelsManager,
        tangemIconProvider: CommonTangemIconProvider(hasNFCInteraction: true)
    )
    let expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(
        userWalletId: userWalletModel.userWalletId,
        refcode: userWalletModel.refcodeProvider?.getRefcode()
    )
    let pendingExpressTxsManager = CommonPendingExpressTransactionsManager(
        userWalletId: userWalletModel.userWalletId.stringValue,
        tokenItem: walletModel.tokenItem,
        walletModelUpdater: walletModel,
        expressAPIProvider: expressAPIProvider,
        expressRefundedTokenHandler: ExpressRefundedTokenHandlerMock()
    )
    let pendingOnrampTxsManager = CommonPendingOnrampTransactionsManager(
        userWalletId: userWalletModel.userWalletId.stringValue,
        tokenItem: walletModel.tokenItem,
        expressAPIProvider: expressAPIProvider
    )
    let pendingTxsManager = CompoundPendingTransactionsManager(
        first: pendingExpressTxsManager,
        second: pendingOnrampTxsManager
    )
    let coordinator = TokenDetailsCoordinator()

    let bannerNotificationManager = BannerNotificationManager(
        userWalletInfo: userWalletModel.userWalletInfo,
        placement: .tokenDetails(walletModel.tokenItem),
    )

    let yieldModuleNoticeInteractor = YieldModuleNoticeInteractor()

    TokenDetailsView(viewModel: .init(
        userWalletInfo: userWalletModel.userWalletInfo,
        walletModel: walletModel,
        notificationManager: notifManager,
        bannerNotificationManager: bannerNotificationManager,
        userTokensManager: userWalletModel.userTokensManager,
        pendingExpressTransactionsManager: pendingTxsManager,
        xpubGenerator: nil,
        coordinator: coordinator,
        tokenRouter: SingleTokenRouter(
            userWalletInfo: userWalletModel.userWalletInfo,
            coordinator: coordinator,
            yieldModuleNoticeInteractor: yieldModuleNoticeInteractor
        ),
        pendingTransactionDetails: nil
    ))
}
