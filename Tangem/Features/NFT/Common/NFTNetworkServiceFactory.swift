//
//  NFTNetworkServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemNFT
import TangemNetworkUtils

struct NFTNetworkServiceFactory {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func makeNetworkService(for tokenItem: TokenItem) -> NFTNetworkService? {
        guard let nftChain = NFTChainConverter.convert(tokenItem.blockchain) else {
            return nil
        }

        switch nftChain {
        case .ethereum,
             .polygon,
             .bsc,
             .avalanche,
             .fantom,
             .cronos,
             .arbitrum,
             .gnosis,
             .chiliz,
             .base,
             .optimism,
             .moonbeam,
             .moonriver:
            return MoralisNFTNetworkService(
                networkConfiguration: TangemProviderConfiguration.ephemeralConfiguration,
                headers: [
                    APIHeaderKeyInfo(
                        headerName: Constants.xAPIKeyHeaderName,
                        headerValue: keysManager.moralisAPIKey
                    ),
                ],
                chain: nftChain
            )
        case .solana:
            return NFTScanNFTNetworkService(
                networkConfiguration: TangemProviderConfiguration.ephemeralConfiguration,
                headers: [
                    APIHeaderKeyInfo(
                        headerName: Constants.xAPIKeyHeaderName,
                        headerValue: keysManager.nftScanAPIKey
                    ),
                ],
                chain: nftChain
            )
        }
    }
}

// MARK: - Constants

private extension NFTNetworkServiceFactory {
    enum Constants {
        static let xAPIKeyHeaderName = "X-API-KEY"
    }
}
