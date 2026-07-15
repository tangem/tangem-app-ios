//
//  SingleWalletMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct SingleWalletMainContentView: View {
    @ObservedObject var viewModel: SingleWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            ScrollableButtonsView(itemsHorizontalOffset: 16, buttonsInfo: viewModel.actionButtons)

            bannersSection

            MarketPriceView(
                currencySymbol: viewModel.currencySymbol,
                price: viewModel.rateFormatted,
                priceChangeState: viewModel.priceChangeState,
                miniChartData: viewModel.miniChartData,
                tapAction: viewModel.openMarketsTokenDetails
            )

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
        }
        .padding(.horizontal, 16)
        .bindAlert($viewModel.alert)
    }

    @ViewBuilder
    private var bannersSection: some View {
        ForEach(viewModel.notificationInputs) { input in
            NotificationView(input: input)
        }

        ForEach(viewModel.tokenNotificationInputs) { input in
            NotificationView(input: input)
        }

        if let walletPromoBannerViewModel = viewModel.walletPromoBannerViewModel {
            WalletPromoBannerView(viewModel: walletPromoBannerViewModel)
        }

        PromotionNotificationsView(viewModel: viewModel.promotionNotificationsViewModel)
    }
}

// MARK: - Previews

#Preview {
    let viewModel: SingleWalletMainContentViewModel = {
        let userWalletModel = FakeUserWalletModel.xrpNote

        let accountModel = userWalletModel
            .accountModelsManager
            .cryptoAccountModels[0]

        let walletModel = accountModel
            .walletModelsManager
            .walletModels[0]

        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [userWalletModel])

        let expressStatusPollingHelper = ExpressStatusPollingHelper(
            exchangePoller: FakeExpressStatusPoller<ExchangeStatusPollIteration>(),
            onrampPoller: FakeExpressStatusPoller<OnrampStatusPollIteration>(),
            enricherFactory: { nil }
        )

        return SingleWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            promotionNotificationsManager: FakePromotionNotificationsManager(),
            pendingExpressTransactionsManager: FakePendingExpressTransactionsManager(),
            expressStatusPollingHelper: expressStatusPollingHelper,
            tokenNotificationManager: FakeUserWalletNotificationManager(),
            rateAppController: RateAppControllerStub(),
            tokenRouter: SingleTokenRoutableMock(),
            delegate: nil,
            coordinator: nil,
            accountModel: accountModel
        )
    }()

    SingleWalletMainContentView(viewModel: viewModel)
        .background(Colors.Background.secondary)
}
