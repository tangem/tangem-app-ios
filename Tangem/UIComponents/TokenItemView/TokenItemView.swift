//
//  TokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemView: View {
    @ObservedObject var viewModel: TokenItemViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TokenItemViewLeadingComponent(
                name: viewModel.name,
                imageURL: viewModel.imageURL,
                blockchainIconName: viewModel.blockchainIconName,
                hasMonochromeIcon: viewModel.hasMonochromeIcon
            )

            TokenItemViewMiddleComponent(
                name: viewModel.name,
                balance: viewModel.balanceCrypto,
                hasPendingTransactions: viewModel.hasPendingTransactions,
                hasError: viewModel.networkUnreachable || viewModel.missingDerivation
            )

            Spacer(minLength: 0.0)

            TokenItemViewTrailingComponent(
                hasError: viewModel.networkUnreachable || viewModel.missingDerivation,
                errorMessage: viewModel.errorMessage,
                balanceFiat: viewModel.balanceFiat,
                priceChangeState: viewModel.priceChangeState
            )
        }
        .padding(14)
        // We need this background for correctly handling tap gesture
        // and because long tap gesture not correctly drawing cell
        .background(Colors.Background.primary.cornerRadiusContinuous(13))
        .onTapGesture(perform: viewModel.tapAction)
    }
}

struct TokenItemView_Previews: PreviewProvider {
    static let infoProvider = FakeTokenItemInfoProvider(walletManagers: [.ethWithTokensManager, .btcManager, .polygonWithTokensManager, .xrpManager])

    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(infoProvider.viewModels, id: \.id) { model in
                TokenItemView(viewModel: model)
            }
        }
    }
}
