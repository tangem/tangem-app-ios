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

struct NFTCollectionDisclosureGroupView: View {
    let viewModel: NFTCompactCollectionViewModel

    @State
    private var isOpened = false

    var body: some View {
        discslosureGroup
    }

    private var discslosureGroup: some View {
        CustomDisclosureGroup(
            isExpanded: isOpened,
            transition: .opacity,
            actionOnClick: {
                withAnimation {
                    isOpened.toggle()
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            },
            alignment: .leading,
            prompt: { label },
            expandedView: {
                NFTAssetsGridView(viewModel: viewModel.assetsGridViewModel)
                    .padding(.top, Constants.gridViewTopPadding)
                    .padding(.bottom, Constants.gridViewBottomPadding)
            }
        )
        .buttonStyle(.defaultScaled)
        .frame(maxWidth: .infinity)
    }

    private var label: some View {
        NFTCollectionRow(
            iconURL: viewModel.logoURL,
            iconOverlayImage: viewModel.blockchainImage,
            title: viewModel.name,
            subtitle: "\(viewModel.numberOfItems) items", // [REDACTED_TODO_COMMENT]
            isExpanded: isOpened
        )
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
                derivationPath: nil,
                contractType: .erc1155,
                name: "My awesome collection",
                description: "",
                logoURL: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!,
                assets: (0 ... 10).map {
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
            ),
            nftChainIconProvider: DummyProvider()
        )
    )
}
#endif
