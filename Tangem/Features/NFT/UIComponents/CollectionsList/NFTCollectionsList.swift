//
//  NFTCollectionsExpandableList.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

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
import TangemNFT

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
                        assets: [
                            NFTAsset(
                                assetIdentifier: "some11",
                                collectionIdentifier: "some",
                                chain: .solana,
                                derivationPath: nil,
                                contractType: .erc1155,
                                ownerAddress: "",
                                name: "Name1",
                                description: nil,
                                media: nil,
                                rarity: nil,
                                traits: []
                            ),
                        ]
                    )
                }
            )
        )
        .padding(16)
    }
}
#endif
