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
        switch viewModel.state {
        case .loading:
            skeleton

        case .loaded(let nftAsset):
            Button(action: viewModel.didClick) {
                makeContent(from: nftAsset)
            }
            .buttonStyle(.defaultScaled)
        }
    }

    private func makeContent(from asset: NFTAsset) -> some View {
        VStack(alignment: .leading, spacing: Constants.iconTextsSpacing) {
            makeIcon(media: asset.media)
            makeTexts(title: asset.name, subtitle: "0.15 ETH") // Price should be taken from somewhere
        }
        .frame(maxWidth: .infinity)
    }

    private var skeleton: some View {
        VStack(alignment: .leading, spacing: Constants.iconTextsSpacing) {
            Color.clear
                .skeletonable(
                    isShown: true,
                    size: Constants.imageSize,
                    radius: SquaredOrRectangleImageView.Constants.cornerRadius
                )

            VStack(alignment: .leading, spacing: 10) {
                Color.clear
                    .skeletonable(
                        isShown: true,
                        size: .init(width: 70, height: Constants.textSkeletonsHeight),
                        radius: Constants.textSkeletonsCornerRadius
                    )

                Color.clear
                    .skeletonable(
                        isShown: true,
                        size: .init(width: 52, height: Constants.textSkeletonsHeight),
                        radius: Constants.textSkeletonsCornerRadius
                    )
            }
        }
        .frame(width: Constants.imageSize.width)
    }

    private func makeIcon(media: NFTMedia?) -> some View {
        SquaredOrRectangleImageView(media: media)
    }

    private func makeTexts(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Text(subtitle)
                .style(Fonts.Bold.subheadline, color: Colors.Text.tertiary)
        }
    }
}

extension NFTCompactAssetView {
    enum Constants {
        static let imageSize: CGSize = .init(bothDimensions: 152)
        static let textSkeletonsCornerRadius: CGFloat = 4
        static let textSkeletonsHeight: CGFloat = 12

        static let iconTextsSpacing: CGFloat = 12
    }
}

#if DEBUG
#Preview("Loaded") {
    NFTCompactAssetView(
        viewModel: NFTCompactAssetViewModel(
            state: .loaded(
                NFTAsset(
                    assetIdentifier: "some",
                    collectionIdentifier: "some1",
                    chain: .solana,
                    contractType: .unknown,
                    ownerAddress: "",
                    name: "My asset",
                    description: "",
                    media: NFTMedia(kind: .image, url: URL(string: "https://cusethejuice.com/cuse-box/assets-cuse-dalle/80.png")!),
                    rarity: nil,
                    traits: []
                )
            ),
            openAssetDetailsAction: { _ in }
        )
    )
}

#Preview("Loading") {
    NFTCompactAssetView(
        viewModel: NFTCompactAssetViewModel(
            state: .loading(id: "1"),
            openAssetDetailsAction: { _ in }
        )
    )
}
#endif
