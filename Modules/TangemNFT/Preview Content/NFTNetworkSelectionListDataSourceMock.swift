//
//  NFTNetworkSelectionListDataSourceMock.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NFTNetworkSelectionListDataSourceMock: NFTNetworkSelectionListDataSource {
    func allSupportedChains() -> [NFTChainItem] {
        return [
            .init(
                nftChain: .polygon(isTestnet: false),
                isCustom: false,
                displayName: "Polygon",
                underlyingIdentifier: nil
            ),
            .init(
                nftChain: .ethereum(isTestnet: false),
                isCustom: false,
                displayName: "Ethereum",
                underlyingIdentifier: nil
            ),
            .init(
                nftChain: .solana,
                isCustom: false,
                displayName: "Solana",
                underlyingIdentifier: nil
            ),
            .init(
                nftChain: .solana,
                isCustom: true,
                displayName: "Solana",
                underlyingIdentifier: nil
            ),
            .init(
                nftChain: .arbitrum,
                isCustom: false,
                displayName: "Arbitrum",
                underlyingIdentifier: nil
            ),
        ]
    }

    func isSupportedChainAvailable(_ nftChainItem: NFTChainItem) -> Bool {
        return nftChainItem.nftChain != .arbitrum
    }
}
