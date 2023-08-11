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
        VStack {
            Text("Hello, single wallet!")
        }
    }
}

struct SingleWalletContentView_Preview: PreviewProvider {
    static let viewModel: SingleWalletMainContentViewModel = {
        let mainCoordinator = MainCoordinator()
        let userWalletModel = FakeUserWalletModel.xrpNote
        let walletModel = userWalletModel.walletModelsManager.walletModels.first!
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
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
            coordinator: mainCoordinator
        )
    }()

    static var previews: some View {
        SingleWalletMainContentView(viewModel: viewModel)
    }
}
