//
//  NFTExplorerLinkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT
import Foundation
import BlockchainSdk

struct NFTExplorerLinkProvider {
    func provide(for asset: NFTAsset) -> URL? {
        guard let tokenAddress = asset.id.collectionIdentifier else {
            return nil
        }

        let blockchain = NFTChainConverter.convert(asset.id.chain, version: .v2)

        let provider = ExternalLinkProviderFactory().makeProvider(
            for: blockchain.isEvm ? .ethereum(testnet: false) : blockchain
        )

        let exploreURL = provider.nftURL(
            tokenAddress: tokenAddress,
            tokenID: asset.id.assetIdentifier
        )

        return exploreURL
    }
}
