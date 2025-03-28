//
//  NFTCollectionDisclosureGroupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemNFT

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
            transition: .opacity.combined(with: .move(edge: .top)),
            actionOnClick: { withAnimation { isOpened.toggle() }},
            prompt: { label },
            expandedView: {
                Text("Todo next")
                    .foregroundStyle(Color.red)
            }
        )
        .buttonStyle(.defaultScaled)
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

#if DEBUG
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
                assets: []
            ),
            version: .v2
        )
    )
}
#endif
