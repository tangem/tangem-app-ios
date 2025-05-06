//
//  NFTAssetsGridView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

struct NFTAssetsGridView: View {
    private let gridItems = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    let viewModel: NFTAssetsGridViewModel

    var body: some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: Constants.rowsSpacing) {
            ForEach(viewModel.assetsViewModels, id: \.id) { viewModel in
                NFTCompactAssetView(viewModel: viewModel)
            }
        }
    }
}

extension NFTAssetsGridView {
    enum Constants {
        static let interitemSpacing: CGFloat = 12
        static let rowsSpacing: CGFloat = 20
    }
}

#if DEBUG
#Preview {
    ScrollView {
        NFTAssetsGridView(viewModel: NFTAssetsGridViewModel(assetsViewModels: (0 ... 10).map {
            NFTCompactAssetViewModel(
                state: .loaded(
                    NFTAsset(
                        assetIdentifier: "some-\($0)",
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
        }))
        .padding(16)
    }
}
#endif
