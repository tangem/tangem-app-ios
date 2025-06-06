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
    func provide(for assetID: NFTAsset.NFTAssetId) -> URL? {
        // [REDACTED_TODO_COMMENT]
        // The dummy hardcoded `version` is used here since it has no effect on the external URL generation
        let blockchain = NFTChainConverter.convert(assetID.chain, version: .v2)

        guard let provider = ExternalLinkProviderFactory().makeNFTProvider(for: blockchain) else {
            assertionFailure("Cannot construct NFTExternalLinksProvider for \(blockchain.displayName)")
            return nil
        }

        let exploreURL = provider.url(
            tokenAddress: assetID.contractAddress,
            tokenID: assetID.identifier,
            contractType: assetID.contractType.description
        )

        return exploreURL
    }
}
