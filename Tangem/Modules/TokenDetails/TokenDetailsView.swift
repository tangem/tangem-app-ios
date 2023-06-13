//
//  TokenDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenDetailsView: View {
    @ObservedObject var viewModel: TokenDetailsViewModel

    var body: some View {
        RefreshableScrollView(onRefresh: viewModel.onRefresh) {
            VStack {
                BalanceWithButtonsView(viewModel: viewModel.balanceWithButtonsModel)
                Text("Hello, World!")
            }
        }
    }
}

class TokenDetailsRoutableMock: TokenDetailsRoutable {
    func openReceiveScreen() {}
}

struct TokenDetailsView_Preview: PreviewProvider {
//    static let viewModel = TokenDetailsViewModel(coordinator: TokenDetailsCoordinator())

    static var previews: some View {
        EmptyView()
//        TokenDetailsView(viewModel: TokenDetailsViewModel(
//            cardModel: PreviewCard.ethereum.cardModel,
//            walletModel: .init(walletManager: ., derivationStyle: <#T##DerivationStyle?#>),
//            blockchainNetwork: .init(.ethereum(testnet: false)),
//            amountType: .coin,
//            coordinator: TokenDetailsRoutableMock()
//        ))
//        TokenDetailsView(viewModel: viewModel)
    }
}
