//
//  NFTSendAmountCompactContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemNFT

struct NFTSendAmountCompactContentView: View {
    let viewModel: NFTSendAmountCompactContentViewModel
    let borderColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            HStack(spacing: 0.0) {
                Text(viewModel.sectionTitle)
                    .style(Fonts.Bold.footnote.weight(.semibold), color: Colors.Text.tertiary)

                Spacer()
            }

            HStack(spacing: 12.0) {
                NFTSendAssetImageViewFactory(nftChainIconProvider: viewModel.nftChainIconProvider)
                    .makeImageView(for: viewModel.asset, borderColor: borderColor, cornerRadius: 8.0)
                    .frame(size: .init(bothDimensions: 36.0))

                VStack(alignment: .leading, spacing: 2.0) {
                    Text(viewModel.assetTitle)
                        .style(Fonts.Bold.subheadline.weight(.medium), color: Colors.Text.primary1)

                    Text(viewModel.assetSubtitle)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                }
            }
        }
        .padding(.horizontal, 4.0)
    }
}
