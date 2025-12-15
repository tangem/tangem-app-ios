//
//  TokenDetailsHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

struct TokenDetailsHeaderView: View {
    let viewModel: TokenDetailsHeaderViewModel

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.tokenName)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                    .accessibilityIdentifier(TokenAccessibilityIdentifiers.tokenNameLabel)

                HStack(spacing: 6) {
                    Text(viewModel.networkPrefix)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    if let networkIconAsset = viewModel.networkIconAsset {
                        networkIconAsset.image
                            .resizable()
                            .frame(size: .init(bothDimensions: 18))
                    }

                    if let networkSuffix = viewModel.networkSuffix {
                        Text(networkSuffix)
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                    }
                }
            }

            Spacer()

            TokenIcon(
                tokenIconInfo: .init(
                    name: "",
                    blockchainIconAsset: nil,
                    imageURL: viewModel.imageURL,
                    isCustom: false,
                    customTokenColor: viewModel.customTokenColor
                ),
                size: IconViewSizeSettings.tokenDetails.iconSize
            )
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    private static var tokenItem: TokenItem {
        .token(.inverseBTCBlaBlaBlaMock, .init(.polygon(testnet: false), derivationPath: nil))
        //        .blockchain(.avalanche(testnet: false))
        //        .token(.sushiMock, .ethereum(testnet: false))
    }

    static var previews: some View {
        VStack {
            TokenDetailsHeaderView(viewModel: .init(tokenItem: tokenItem))
                .padding(16)

            Spacer()
        }
    }
}
