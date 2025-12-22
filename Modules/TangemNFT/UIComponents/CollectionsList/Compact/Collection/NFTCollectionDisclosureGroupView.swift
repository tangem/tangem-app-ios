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
    let viewModel: NFTCollectionDisclosureGroupViewModel
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
            // Implementation details. DrawingGroup ruins display of GIFs due
            // to flattening subtree of views into single view before rendering it
            // From the docs:
            // Views backed by native platform views may not render into the image. Instead, they log a warning and display a placeholder image to highlight the error.
            useDrawingGroup: !viewModel.containsGIFs,
            prompt: { label },
            expandedView: { content }
        )
        .buttonStyle(.defaultScaled)
        .disabled(!viewModel.isExpandable)
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
        .padding(.vertical, 15.0)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            buildGridView(with: .init(assetsCount: viewModel.numberOfItems))

        case .success(let viewModel):
            buildGridView(with: viewModel)

        case .failure:
            errorView
        }
    }

    private func buildGridView(with viewModel: NFTAssetsGridViewModel) -> some View {
        NFTAssetsGridView(viewModel: viewModel)
            .padding(.vertical, 12.0)
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

#if DEBUG
struct DummyProvider: NFTChainIconProvider {
    func provide(by nftChain: NFTChain) -> ImageType {
        Tokens.solanaFill
    }
}

#Preview {
    NFTCollectionDisclosureGroupView(
        viewModel: NFTCollectionDisclosureGroupViewModel(
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
                assetsCount: 0,
                assetsResult: .init(
                    value: (0 ... 2).map {
                        NFTAsset(
                            assetIdentifier: "some-\($0)",
                            assetContractAddress: "some1",
                            chain: .solana,
                            contractType: .unknown,
                            decimalCount: 0,
                            ownerAddress: "",
                            name: "My asset",
                            description: "",
                            salePrice: nil,
                            mediaFiles: [
                                NFTMedia(kind: .image, url: URL(string: "https://cusethejuice.com/cuse-box/assets-cuse-dalle/80.png")!),
                            ],
                            rarity: nil,
                            traits: []
                        )
                    }
                )
            ),
            assetsState: .loading,
            dependencies: NFTCollectionsListDependencies(
                nftChainIconProvider: DummyProvider(),
                nftChainNameProviding: NFTChainNameProviderMock(),
                priceFormatter: NFTPriceFormatterMock(),
                analytics: .empty
            ),
            openAssetDetailsAction: { _ in },
            onCollectionTap: { _, _ in }
        )
    )
}
#endif
