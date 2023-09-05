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

    private let notificationTransition: AnyTransition = .scale.combined(with: .opacity)

    var body: some View {
        VStack(spacing: 14) {
            ScrollableButtonsView(itemsHorizontalOffset: 16, buttonsInfo: viewModel.actionButtons)

            ForEach(viewModel.notificationInputs) { input in
                NotificationView(input: input)
                    .transition(notificationTransition)
            }

            TransactionsListView(
                state: viewModel.transactionHistoryState,
                exploreAction: viewModel.openExplorer,
                reloadButtonAction: viewModel.reloadHistory,
                isReloadButtonBusy: viewModel.isReloadingTransactionHistory,
                buyButtonAction: viewModel.canBuyCrypto ? viewModel.openBuyCryptoIfPossible : nil,
                fetchMore: viewModel.fetchMoreHistory()
            )
            .padding(.bottom, 40)
        }
        .animation(.default, value: viewModel.notificationInputs)
        .padding(.horizontal, 16)
    }
}

struct SingleWalletContentView_Preview: PreviewProvider {
    static let viewModel: SingleWalletMainContentViewModel = {
        let mainCoordinator = MainCoordinator()
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
            userTokensManager: userWalletModel.userTokensManager,
            exchangeUtility: cryptoUtility,
            userWalletNotificationManager: FakeUserWalletNotificationManager(),
            coordinator: mainCoordinator
        )
    }()

    static var previews: some View {
        SingleWalletMainContentView(viewModel: viewModel)
            .background(Colors.Background.secondary)
    }
}
