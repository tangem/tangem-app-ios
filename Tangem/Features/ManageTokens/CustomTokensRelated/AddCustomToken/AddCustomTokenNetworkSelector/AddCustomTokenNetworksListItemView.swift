//
//  AddCustomTokenNetworkSelectorItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct AddCustomTokenNetworksListItemView: View {
    @ObservedObject var viewModel: AddCustomTokenNetworksListItemViewModel

    var body: some View {
        HStack(spacing: 12) {
            NetworkIcon(
                imageAsset: viewModel.iconAsset,
                isActive: false,
                isMainIndicatorVisible: false,
                size: CGSize(bothDimensions: 24.0)
            )

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.networkName)
                    .lineLimit(1)
                    .layoutPriority(-1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(viewModel.currencySymbol)
                    .lineLimit(1)
                    .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            }

            Spacer(minLength: 0)

            if viewModel.isSelected {
                Assets.check.image
                    .frame(width: 20, height: 20)
                    .foregroundColor(Colors.Icon.accent)
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.didTapWallet()
        }
    }
}

#if DEBUG

struct AddCustomTokenNetworkSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            AddCustomTokenNetworksListItemView(
                viewModel: .init(
                    networkId: "",
                    iconAsset: Tokens.ethereumFill,
                    networkName: "Ethereum",
                    currencySymbol: "ETH",
                    isSelected: true,
                    didTapWallet: {}
                )
            )

            AddCustomTokenNetworksListItemView(
                viewModel: .init(
                    networkId: "",
                    iconAsset: Tokens.solanaFill,
                    networkName: "Solana",
                    currencySymbol: "SOL",
                    isSelected: false,
                    didTapWallet: {}
                )
            )

            AddCustomTokenNetworksListItemView(
                viewModel: .init(
                    networkId: "",
                    iconAsset: Tokens.bscFill,
                    networkName: "Binance smartest chain on the planet and maybe even the Universe",
                    currencySymbol: "BNB",
                    isSelected: true,
                    didTapWallet: {}
                )
            )
        }
        .previewLayout(.fixed(width: 400, height: 300))
    }
}

#endif // DEBUG
