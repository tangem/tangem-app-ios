//
//  NFTAssetCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT
import TangemLocalization

struct NFTAssetCompactViewModel {
    var walletTitle: String { Localization.sendFromWalletName(wallet) }
    var assetTitle: String { asset.name }
    var assetSubtitle: String { collection.name }

    let wallet: String
    let asset: NFTAsset
    let nftChainIconProvider: NFTChainIconProvider
    let collection: NFTCollection

    init(
        wallet: String,
        asset: NFTAsset,
        collection: NFTCollection,
        nftChainIconProvider: NFTChainIconProvider
    ) {
        self.wallet = wallet
        self.asset = asset
        self.collection = collection
        self.nftChainIconProvider = nftChainIconProvider
    }
}
