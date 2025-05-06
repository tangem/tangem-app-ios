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
            prompt: { label },
            expandedView: { gridView }
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
    private var gridView: some View {
        switch viewModel.viewState {
        case .loading:
            // [REDACTED_TODO_COMMENT]
            Color
                .clear
                .frame(height: 250)
                .overlay { Text("Loading") }
        case .loaded(let viewModel):
            NFTAssetsGridView(viewModel: viewModel)
                .padding(.top, Constants.gridViewTopPadding)
                .padding(.bottom, Constants.gridViewBottomPadding)
        case .failedToLoad(let error):
            // [REDACTED_TODO_COMMENT]
            Color
                .clear
                .frame(height: 250)
                .overlay { Text("Error: \(error.localizedDescription)") }
        }
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
