//
//  NFTCollectionsExpandableList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct NFTCollectionsList: View {
    @ObservedObject var viewModel: NFTCollectionsListViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Constants.interitemSpacing) {
                ForEach(viewModel.collectionsViewModels, id: \.id) { collectionViewModel in
                    NFTCollectionDisclosureGroupView(viewModel: collectionViewModel)
                }
            }
        }
        .roundedBackground(
            with: Colors.Background.primary,
            padding: Constants.padding,
            radius: Constants.cornerRadius
        )
    }
}

extension NFTCollectionsList {
    enum Constants {
        static let padding: CGFloat = 14
        static let interitemSpacing: CGFloat = 30
        static let cornerRadius: CGFloat = 14
    }
}

#if DEBUG
#Preview {
    ZStack {
        Colors.Background.secondary
        NFTCollectionsList(
            viewModel: .init(
                collections: (0 ... 10).map {
                    NFTCollection(
                        collectionIdentifier: "some-\($0)",
                        chain: .solana,
                        derivationPath: nil,
                        contractType: .erc1155,
                        name: "My awesome collection",
                        description: "",
                        logoURL: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
                        assets: (0 ... 3).map {
                            NFTAsset(
                                assetIdentifier: "some-\($0)",
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
                        }
                    )
                },
                nftChainIconProvider: DummyProvider()
            )
        )
        .padding(16)
    }
}
#endif
