//
//  NFTAssetCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemNFT
import TangemLocalization

struct NFTAssetCompactView: View {
    let viewModel: NFTAssetCompactViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: .zero) {
                SendTokenHeaderView(header: viewModel.header)

                Spacer()
            }

            HStack(spacing: .zero) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.assetTitle)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)

                    Text(viewModel.assetSubtitle)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                }

                Spacer(minLength: 4)

                NFTSendAssetImageViewFactory(nftChainIconProvider: viewModel.nftChainIconProvider)
                    .makeImageView(for: viewModel.asset, borderColor: Colors.Background.action, cornerRadius: 8)
                    .frame(size: .init(bothDimensions: 36))
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 14, horizontalPadding: 14)
    }
}
