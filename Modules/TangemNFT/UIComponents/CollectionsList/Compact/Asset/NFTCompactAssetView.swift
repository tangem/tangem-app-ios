//
//  NFTCompactAssetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct NFTCompactAssetView: View {
    var viewModel: NFTCompactAssetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.iconTextsSpacing) {
            icon
            texts
        }
        .frame(width: Constants.imageSize.width)
    }

    private var icon: some View {
        IconView(
            url: viewModel.mediaURL,
            size: Constants.imageSize,
            cornerRadius: Constants.cornerRadius,
            forceKingfisher: true,
            placeholder: { placeholder }
        )
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: Constants.textsSpacing) {
            Text(viewModel.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
            Text(viewModel.subtitle)
                .style(Fonts.Bold.subheadline, color: Colors.Text.tertiary)
        }
    }

    private var placeholder: some View {
        Color.clear
            .frame(size: Constants.imageSize)
            .skeletonable(
                isShown: true,
                width: Constants.imageSize.width,
                height: Constants.imageSize.height,
                radius: Constants.cornerRadius
            )
    }
}

extension NFTCompactAssetView {
    enum Constants {
        static let imageSize: CGSize = .init(bothDimensions: 152)
        static let cornerRadius: CGFloat = 14
        static let iconTextsSpacing: CGFloat = 12
        static let textsSpacing: CGFloat = 2
    }
}

#if DEBUG
#Preview {
    NFTCompactAssetView(
        viewModel: NFTCompactAssetViewModel(
            nftAsset: NFTAsset(
                assetIdentifier: "some",
                collectionIdentifier: "some1",
                chain: .solana,
                derivationPath: nil,
                contractType: .splToken2022,
                ownerAddress: "",
                name: "My asset",
                description: "",
                media: NFTAsset.Media(kind: .image, url: URL(string: "https://cusethejuice.com/cuse-box/assets-cuse-dalle/80.png")!),
                rarity: nil,
                traits: []
            )
        )
    )
}
#endif
