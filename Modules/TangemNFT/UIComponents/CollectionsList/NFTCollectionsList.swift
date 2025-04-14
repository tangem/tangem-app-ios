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
import TangemUI
import TangemLocalization

struct NFTCollectionsList: View {
    @ObservedObject var viewModel: NFTCollectionsListViewModel

    var body: some View {
        switch viewModel.state {
        case .empty:
            emptyView
        case .nonEmpty(let collections):
            nonEmptyContentView(collections: collections)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 0) {
            Assets.Nft.Collections.noCollections.image
                .resizable()
                .frame(size: Constants.EmptyView.imageSize)
                .padding(.bottom, Constants.EmptyView.imageTextsSpacing)

            noCollectionsTexts
                .padding(.bottom, Constants.EmptyView.textsButtonSpacing)

            receiveButton(souldAddShadow: false)
                .padding(.horizontal, Constants.EmptyView.buttonHPaddingInsideContainer)
        }
        .padding(.horizontal, Constants.EmptyView.horizontalPadding)
    }

    private var noCollectionsTexts: some View {
        VStack(spacing: Constants.EmptyView.titleSubtitleSpacing) {
            Text(Localization.nftCollectionsEmptyTitle)
                .style(Fonts.BoldStatic.title3, color: Colors.Text.primary1)
            Text(Localization.nftCollectionsEmptyDescription)
                .style(Fonts.Regular.callout, color: Colors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func nonEmptyContentView(collections: [NFTCompactCollectionViewModel]) -> some View {
        ZStack {
            collectionsContent(from: collections)
            receiveButtonContainer
        }
    }

    private func collectionsContent(from collections: [NFTCompactCollectionViewModel]) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Constants.interitemSpacing) {
                ForEach(collections, id: \.id) { collectionViewModel in
                    NFTCollectionDisclosureGroupView(viewModel: collectionViewModel)
                }
            }
        }
        .roundedBackground(
            with: Colors.Background.primary,
            padding: Constants.padding,
            radius: Constants.cornerRadius
        )
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var receiveButtonContainer: some View {
        VStack(spacing: 0) {
            Spacer()
            receiveButton(souldAddShadow: true)
        }
    }

    private func receiveButton(souldAddShadow: Bool) -> some View {
        MainButton(title: Localization.nftCollectionsReceive, action: {})
            .if(souldAddShadow) { view in
                view.background(
                    ListFooterOverlayShadowView()
                )
            }
    }
}

extension NFTCollectionsList {
    enum Constants {
        enum EmptyView {
            static let imageTextsSpacing: CGFloat = 24
            static let titleSubtitleSpacing: CGFloat = 8
            static let textsButtonSpacing: CGFloat = 56
            static let imageSize: CGSize = .init(bothDimensions: 76)

            static let horizontalPadding: CGFloat = 32
            static let buttonHPaddingInsideContainer: CGFloat = 40
        }

        static let padding: CGFloat = 14
        static let interitemSpacing: CGFloat = 30
        static let cornerRadius: CGFloat = 14
        static let receiveButtonYOffset: CGFloat = -6
    }
}

#if DEBUG
#Preview("Multiple collections") {
    ZStack {
        Colors.Background.secondary
        NFTCollectionsList(
            viewModel: .init(
                collections: (0 ... 20).map {
                    NFTCollection(
                        collectionIdentifier: "some-\($0)",
                        chain: .solana,
                        contractType: .erc1155,
                        ownerAddress: "0x79D21ca8eE06E149d296a32295A2D8A97E52af52",
                        name: "My awesome collection",
                        description: "",
                        logoURL: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
                        assetsCount: nil,
                        assets: (0 ... 3).map {
                            NFTAsset(
                                assetIdentifier: "some-\($0)",
                                collectionIdentifier: "some1",
                                chain: .solana,
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
        .padding(.horizontal, 16)
    }
}

#Preview("No Collections") {
    ZStack {
        Colors.Background.secondary
        NFTCollectionsList(
            viewModel: .init(
                collections: [],
                nftChainIconProvider: DummyProvider()
            )
        )
        .padding(.horizontal, 16)
    }
}
#endif
