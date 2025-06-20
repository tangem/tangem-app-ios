//
//  NFTDummyCollectionMapper.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemLocalization

enum NFTDummyCollectionMapper {
    static func map(
        chain: NFTChain,
        assets: [NFTAsset],
        assetsCount: Int,
        contractType: NFTContractType,
        ownerAddress: String,
        description: String?,
        media: NFTMedia?
    ) -> NFTCollection {
        NFTCollection(
            collectionIdentifier: chain.id,
            chain: chain,
            contractType: contractType,
            ownerAddress: ownerAddress,
            name: Localization.nftNoCollection,
            description: description,
            media: media,
            assetsCount: assetsCount,
            assetsResult: NFTPartialResult(value: assets)
        )
    }
}
