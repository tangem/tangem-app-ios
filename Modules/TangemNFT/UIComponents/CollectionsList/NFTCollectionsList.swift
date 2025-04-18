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

public struct NFTCollectionsList: View {
    @ObservedObject var viewModel: NFTCollectionsListViewModel
    @State private var hasBeenScrolledUp = false

    public init(viewModel: NFTCollectionsListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        contentView
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .noCollections:
            noCollectionsView
        case .collectionsAvailale(let collections):
            nonEmptyContentView(collections: collections)
                .nftListSearchable(text: $viewModel.searchEntry, isAutomatic: hasBeenScrolledUp)
        }
    }

    private var noCollectionsView: some View {
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
            if collections.isNotEmpty {
                collectionsContent(from: collections)
            } else {
                emptySearchView
            }

            receiveButtonContainer
        }
    }

    private var emptySearchView: some View {
        Text(Localization.nftEmptySearch)
            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
    }

    private func collectionsContent(from collections: [NFTCompactCollectionViewModel]) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: Constants.interitemSpacing) {
                ForEach(collections, id: \.id) { collectionViewModel in
                    NFTCollectionDisclosureGroupView(viewModel: collectionViewModel)
                }
            }
            .roundedBackground(
                with: Colors.Background.primary,
                padding: Constants.padding,
                radius: Constants.cornerRadius
            )
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged {
                    hasBeenScrolledUp = $0.translation.height < 0
                }
        )
    }

    private var receiveButtonContainer: some View {
        VStack(spacing: 0) {
            Spacer()
            receiveButton(souldAddShadow: true)
        }
        .ignoresSafeArea(.keyboard)
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

private extension View {
    func nftListSearchable(text: Binding<String>, isAutomatic: Bool) -> some View {
        searchable(
            text: text,
            placement: .navigationBarDrawer(displayMode: isAutomatic ? .automatic : .always)
        )
        .ignoresSafeArea(.container, edges: .bottom)
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
        static let searchBarCollectionsSpacing: CGFloat = 12
    }
}

#if DEBUG
#Preview("Multiple collections") {
    NavigationView {
        ZStack {
            Colors.Background.secondary
            NFTCollectionsList(
                viewModel: .init(
                    collections: (0 ... 20).map {
                        NFTCollection(
                            collectionIdentifier: "some-\($0)",
                            chain: .solana,
                            contractType: .erc1155,
                            ownerAddress: "",
                            name: "My awesome collection",
                            description: "",
                            logoURL: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
                            assetsCount: 12,
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
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("NFT collections")
        }
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
