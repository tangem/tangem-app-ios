//
//  NewNFTSendAmountStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT

struct NFTAssetStepBuilder {
    let asset: NFTAsset
    let collection: NFTCollection

    func makeNFTAssetCompactViewModel(header: SendTokenHeader) -> NFTAssetCompactViewModel {
        let viewModel = NFTAssetCompactViewModel(
            header: header,
            asset: asset,
            collection: collection,
            nftChainIconProvider: NetworkImageProvider()
        )

        return viewModel
    }
}
