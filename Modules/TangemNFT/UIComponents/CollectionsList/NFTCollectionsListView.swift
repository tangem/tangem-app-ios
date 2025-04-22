//
//  NFTCollectionsListView.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemUI
import TangemLocalization

public struct NFTCollectionsListView: View {
    @ObservedObject var viewModel: NFTCollectionsListViewModel

    @State private var hasBeenScrolledDown: Bool = false

    @State private var buttonHeight: CGFloat = 0
    @State private var shouldShowShadow: Bool = true

    @State private var buttonMinY: CGFloat = 0
    @State private var contentMaxY: CGFloat = 0

    public init(viewModel: NFTCollectionsListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        content
            .navigationTitle(Localization.nftWalletTitle)
            .padding(.horizontal, Constants.horizontalPadding)
            .background(Colors.Background.secondary)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .noCollections:
            noCollectionsView
        case .collectionsAvailable(let collections):
            nonEmptyContentView(collections: collections)
                .nftListSearchable(text: $viewModel.searchEntry, isAutomatic: hasBeenScrolledDown)
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

            receiveButton(shouldAddShadow: false)
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
            VStack(spacing: 0) {
                LazyVStack(spacing: Constants.interitemSpacing) {
                    ForEach(collections, id: \.id) { collectionViewModel in
                        NFTCollectionDisclosureGroupView(viewModel: collectionViewModel)
                    }
                }
                .roundedBackground(
                    with: Colors.Background.primary,
                    padding: Constants.backgroundPadding,
                    radius: Constants.cornerRadius
                )

                Spacer()
                    .frame(height: buttonHeight + Constants.contentButtonSpacing)
            }
            .readGeometry(\.frame.maxY, inCoordinateSpace: .global, bindTo: $contentMaxY)
            .readContentOffset(inCoordinateSpace: .global) { point in
                shouldShowShadow = contentMaxY > buttonMinY
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged {
                    if !hasBeenScrolledDown {
                        hasBeenScrolledDown = $0.translation.height < 0
                    }
                }
        )
    }

    private var receiveButtonContainer: some View {
        VStack(spacing: 0) {
            Spacer()
            receiveButton(shouldAddShadow: shouldShowShadow)
        }
        .ignoresSafeArea(.keyboard)
    }

    private func receiveButton(shouldAddShadow: Bool) -> some View {
        MainButton(title: Localization.nftCollectionsReceive, action: {})
            .if(shouldAddShadow) { view in
                view.background(
                    ListFooterOverlayShadowView()
                )
            }
            .readGeometry(\.frame, inCoordinateSpace: .global) { frame in
                buttonHeight = frame.height
                buttonMinY = frame.minY
            }
    }
}

private extension View {
    func nftListSearchable(text: Binding<String>, isAutomatic: Bool) -> some View {
        searchable(
            text: text,
            placement: .navigationBarDrawer(displayMode: isAutomatic ? .automatic : .always)
        )
    }
}

extension NFTCollectionsListView {
    enum Constants {
        enum EmptyView {
            static let imageTextsSpacing: CGFloat = 24
            static let titleSubtitleSpacing: CGFloat = 8
            static let textsButtonSpacing: CGFloat = 56
            static let imageSize: CGSize = .init(bothDimensions: 76)

            static let horizontalPadding: CGFloat = 16
            static let buttonHPaddingInsideContainer: CGFloat = 40
        }

        static let horizontalPadding: CGFloat = 16
        static let backgroundPadding: CGFloat = 14
        static let interitemSpacing: CGFloat = 30
        static let cornerRadius: CGFloat = 14

        static let contentButtonSpacing: CGFloat = 16
        static let searchBarCollectionsSpacing: CGFloat = 12
    }
}

#if DEBUG
#Preview("Multiple collections") {
    ZStack {
        Colors.Background.secondary
        NFTCollectionsListView(
            viewModel: .init(
                nftManager: NFTManagerMock(
                    state: .loaded(
                        (0 ... 20).map {
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
                        }
                    )
                ),
                chainIconProvider: DummyProvider(),
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("NFT collections")
    }
}

#Preview("No Collections") {
    ZStack {
        Colors.Background.secondary
        NFTCollectionsListView(
            viewModel: .init(
                nftManager: NFTManagerMock(state: .loaded([])),
                chainIconProvider: DummyProvider(),
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}
#endif
