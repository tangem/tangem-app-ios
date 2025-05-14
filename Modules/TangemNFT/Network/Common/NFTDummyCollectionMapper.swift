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
        ownerAdddress: String
    ) -> NFTCollection {
        NFTCollection(
            collectionIdentifier: chain.id,
            chain: chain,
            contractType: contractType,
            ownerAddress: ownerAdddress,
            name: Localization.nftNoCollection,
            description: nil,
            media: nil,
            assetsCount: assetsCount,
            assets: assets
        )
    }
}
