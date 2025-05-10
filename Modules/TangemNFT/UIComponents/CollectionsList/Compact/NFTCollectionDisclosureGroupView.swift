//
//  NFTCollectionDisclosureGroupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct NFTCollectionDisclosureGroupView: View {
    let viewModel: NFTCompactCollectionViewModel

    @State private var isExpanded: Bool = false

    var body: some View {
        disclosureGroup
    }

    private var disclosureGroup: some View {
        CustomDisclosureGroup(
            isExpanded: isExpanded,
            transition: .opacity,
            actionOnClick: onTap,
            alignment: .leading,
            // Implemetation details. DrawingGroup ruins display of GIFs due
            // to flattening subtree of views into single view before rendering it
            // From the docs:
            // Views backed by native platform views may not render into the image. Instead, they log a warning and display a placeholder image to highlight the error.
            useDrawingGroup: !viewModel.containsGIFs,
            prompt: { label },
            expandedView: { content }
        )
        .buttonStyle(.defaultScaled)
        .frame(maxWidth: .infinity)
    }

    private var label: some View {
        NFTCollectionRow(
            media: viewModel.media,
            iconOverlayImage: viewModel.blockchainImage,
            title: viewModel.name,
            subtitle: Localization.nftCollectionsCount(viewModel.numberOfItems),
            isExpanded: isExpanded
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            buildGridView(with: .init(assetsCount: viewModel.numberOfItems))

        case .loaded(let viewModel):
            buildGridView(with: viewModel)

        case .failedToLoad:
            errorView
        }
    }

    private func buildGridView(with viewModel: NFTAssetsGridViewModel) -> some View {
        NFTAssetsGridView(viewModel: viewModel)
            .padding(.top, Constants.gridViewTopPadding)
            .padding(.bottom, Constants.gridViewBottomPadding)
    }

    private var errorView: some View {
        UnableToLoadDataView(
            isButtonBusy: false,
            retryButtonAction: {
                viewModel.onTap(isExpanded: true)
            }
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 56)
    }

    private func onTap() {
        viewModel.onTap(isExpanded: !isExpanded)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation {
            isExpanded.toggle()
        }
    }
}

extension NFTCollectionDisclosureGroupView {
    enum Constants {
        static let gridViewTopPadding: CGFloat = 26
        static let gridViewBottomPadding: CGFloat = 12
    }
}

#if DEBUG
struct DummyProvider: NFTChainIconProvider {
    func provide(by nftChain: NFTChain) -> ImageType {
        Tokens.solanaFill
    }
}

#Preview {
    NFTCollectionDisclosureGroupView(
        viewModel: NFTCompactCollectionViewModel(
            nftCollection: NFTCollection(
                collectionIdentifier: "some",
                chain: .solana,
                contractType: .erc1155,
                ownerAddress: "0x79D21ca8eE06E149d296a32295A2D8A97E52af52",
                name: "My awesome collection",
                description: "",
                media: .init(
                    kind: .image,
                    url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                ),
                assetsCount: nil,
                assets: (0 ... 2).map {
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
                }
            ),
            assetsState: .loading,
            nftChainIconProvider: DummyProvider(),
            openAssetDetailsAction: { _ in },
            onCollectionTap: { _, _ in }
        )
    )
}
#endif
