//
//  NFTExplorerLinkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemNFT
import TangemFoundation

struct NFTExplorerLinkProvider {
    func provide(for asset: NFTAsset) -> URL? {
        guard let tokenAddress = asset.id.collectionIdentifier else {
            return nil
        }

        // [REDACTED_TODO_COMMENT]
        // The dummy hardcoded `version` is used here since it has no effect on the external URL generation
        let blockchain = NFTChainConverter.convert(asset.id.chain, version: .v2)

        let isTestnet = AppEnvironment.current.isTestnet

        let provider = ExternalLinkProviderFactory().makeProvider(
            for: blockchain.isEvm ? .ethereum(testnet: isTestnet) : blockchain
        )

        let exploreURL = provider.nftURL(
            tokenAddress: tokenAddress,
            tokenID: asset.id.assetIdentifier
        )

        return exploreURL
    }
}
