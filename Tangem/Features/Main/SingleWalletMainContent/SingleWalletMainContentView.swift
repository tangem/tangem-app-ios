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

            if let walletPromoBannerViewModel = viewModel.walletPromoBannerViewModel {
                WalletPromoBannerView(viewModel: walletPromoBannerViewModel)
            }

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
            }

            ForEach(viewModel.tokenNotificationInputs) { input in
                NotificationView(input: input)
            }

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
                exploreTransactionAction: viewModel.openTransactionExplorer,
                reloadButtonAction: viewModel.onButtonReloadHistory,
                isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                fetchMore: viewModel.fetchMoreHistory()
            )
        }
        .padding(.horizontal, 16)
        .bindAlert($viewModel.alert)
    }
}

struct SingleWalletContentView_Preview: PreviewProvider {
    static let viewModel: SingleWalletMainContentViewModel = {
        let mainCoordinator = MainCoordinator()
        let userWalletModel = FakeUserWalletModel.xrpNote
        let walletModel = userWalletModel.walletModelsManager.walletModels.first!
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [userWalletModel])

        return SingleWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            walletModel: userWalletModel.walletModelsManager.walletModels.first!,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            pendingExpressTransactionsManager: FakePendingExpressTransactionsManager(),
            tokenNotificationManager: FakeUserWalletNotificationManager(),
            rateAppController: RateAppControllerStub(),
            tokenRouter: SingleTokenRoutableMock(),
            delegate: nil
        )
    }()

    static var previews: some View {
        SingleWalletMainContentView(viewModel: viewModel)
            .background(Colors.Background.secondary)
    }
}
