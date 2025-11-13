//
//  NFTCollectionDisclosureGroupViewModel+mock.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension NFTCollectionDisclosureGroupViewModel {
    static func mock(name: String, description: String? = nil, media: NFTMedia? = nil) -> Self {
        NFTCollectionDisclosureGroupViewModel(
            nftCollection: NFTCollection(
                collectionIdentifier: name,
                chain: .avalanche,
                contractType: .erc1155,
                ownerAddress: "",
                name: name,
                description: description,
                media: media,
                assetsCount: 12,
                assetsResult: NFTPartialResult<[NFTAsset]>(value: [])
            ),
            assetsState: .loading,
            dependencies: .init(
                nftChainIconProvider: NFTChainIconProviderMock(),
                nftChainNameProviding: NFTChainNameProviderMock(),
                priceFormatter: NFTPriceFormatterMock(),
                analytics: NFTAnalytics.Collections(logReceiveOpen: {}, logDetailsOpen: { _, _ in })
            ),
            openAssetDetailsAction: { _ in },
            onCollectionTap: { _, _ in }
        )
    }
}
