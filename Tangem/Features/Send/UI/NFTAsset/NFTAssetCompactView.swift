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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: .zero) {
                Text(Localization.nftAsset)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()
            }

            HStack(spacing: 12) {
                NFTSendAssetImageViewFactory(nftChainIconProvider: viewModel.nftChainIconProvider)
                    .makeImageView(for: viewModel.asset, borderColor: Colors.Background.action, cornerRadius: 8)
                    .frame(size: .init(bothDimensions: 36))

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.assetTitle)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    Text(viewModel.assetSubtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 14)
    }
}
