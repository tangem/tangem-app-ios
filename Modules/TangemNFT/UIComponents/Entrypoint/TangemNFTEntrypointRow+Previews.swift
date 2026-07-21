//
//  TangemNFTEntrypointRow+Previews.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Previews

#Preview("No collections") {
    ZStack {
        Color.Tangem.Surface.level1
        TangemNFTEntrypointRow(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(state: .success(.init(value: []))),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("One collection") {
    ZStack {
        Color.Tangem.Surface.level1
        TangemNFTEntrypointRow(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: [
                                .init(
                                    collectionIdentifier: "",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                ),
                            ]
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Two collections") {
    ZStack {
        Color.Tangem.Surface.level1
        TangemNFTEntrypointRow(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: (0 ... 1).map {
                                .init(
                                    collectionIdentifier: "\($0)",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                )
                            }
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Four collections") {
    ZStack {
        Color.Tangem.Surface.level1
        TangemNFTEntrypointRow(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: (0 ... 3).map {
                                .init(
                                    collectionIdentifier: "\($0)",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                )
                            }
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}

#Preview("Multiple collections") {
    ZStack {
        Color.Tangem.Surface.level1
        TangemNFTEntrypointRow(
            viewModel: NFTEntrypointViewModel(
                nftManager: NFTManagerMock(
                    state: .success(
                        .init(
                            value: (0 ... 5).map {
                                .init(
                                    collectionIdentifier: "\($0)",
                                    chain: .solana,
                                    contractType: .erc1155,
                                    ownerAddress: "",
                                    name: "",
                                    description: "",
                                    media: .init(
                                        kind: .image,
                                        url: URL(string: "https://cusethejuice.s3.amazonaws.com/cuse-box/assets/compressed-collection.png")!
                                    ),
                                    assetsCount: 2,
                                    assetsResult: []
                                )
                            }
                        )
                    )
                ),
                accountForCollectionsProvider: AccountNFTCollectionProviderMock(),
                navigationContext: NFTNavigationContextMock(),
                analytics: .empty,
                coordinator: nil
            )
        )
        .padding(.horizontal, 16)
    }
}
