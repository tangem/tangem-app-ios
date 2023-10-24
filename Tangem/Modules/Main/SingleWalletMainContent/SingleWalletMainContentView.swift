//
//  SingleWalletMainContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SingleWalletMainContentView: View {
    @ObservedObject var viewModel: SingleWalletMainContentViewModel

    var body: some View {
        VStack(spacing: 14) {
            ScrollableButtonsView(itemsHorizontalOffset: 16, buttonsInfo: viewModel.actionButtons)

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .transition(.notificationTransition)
            }

            ForEach(viewModel.tokenNotificationInputs) { input in
                NotificationView(input: input)
                    .transition(.notificationTransition)
            }

            MarketPriceView(
                currencySymbol: viewModel.currencySymbol,
                price: viewModel.rateFormatted,
                priceChangeState: viewModel.priceChangeState,
                tapAction: nil
            )

            PendingTransactionsListView(
                items: viewModel.pendingTransactionViews,
                exploreTransactionAction: viewModel.openTransactionExplorer
            )

            TransactionsListView(
                state: viewModel.transactionHistoryState,
                exploreAction: viewModel.openExplorer,
                exploreTransactionAction: viewModel.openTransactionExplorer,
                reloadButtonAction: viewModel.reloadHistory,
                isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                fetchMore: viewModel.fetchMoreHistory()
            )
            .padding(.bottom, 40)
        }
        .animation(.default, value: viewModel.notificationInputs)
        .animation(.default, value: viewModel.tokenNotificationInputs)
        .padding(.horizontal, 16)
        .bindAlert($viewModel.alert)
    }
}

struct SingleWalletContentView_Preview: PreviewProvider {
    static let viewModel: SingleWalletMainContentViewModel = {
        let userWalletModel = FakeUserWalletModel.xrpNote
        let walletModel = userWalletModel.walletModelsManager.walletModels.first!
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [userWalletModel])
        let cryptoUtility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.wallet.address,
            amountType: walletModel.amountType
        )

        return SingleWalletMainContentViewModel(
            userWalletModel: userWalletModel,
            walletModel: userWalletModel.walletModelsManager.walletModels.first!,
            exchangeUtility: cryptoUtility,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            tokenNotificationManager: FakeUserWalletNotificationManager(),
            mainViewDelegate: nil,
            tokenRouter: SingleTokenRoutableMock()
        )
    }()

    static var previews: some View {
        SingleWalletMainContentView(viewModel: viewModel)
            .background(Colors.Background.secondary)
    }
}
