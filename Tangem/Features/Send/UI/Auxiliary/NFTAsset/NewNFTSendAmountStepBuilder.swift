//
//  NewNFTSendAmountStepBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT

struct NFTAssetStepBuilder {
    let wallet: String
    let asset: NFTAsset
    let collection: NFTCollection

    func makeNFTAssetCompactViewModel() -> NFTAssetCompactViewModel {
        let viewModel = NFTAssetCompactViewModel(
            wallet: wallet,
            asset: asset,
            collection: collection,
            nftChainIconProvider: NetworkImageProvider()
        )

        return viewModel
    }
}
