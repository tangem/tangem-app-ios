//
//  NFTChainNameProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT

struct NFTChainNameProvider: NFTChainNameProviding {
    func provide(for nftChain: NFTChain) -> String {
        // [REDACTED_TODO_COMMENT]
        let blockchain = NFTChainConverter.convert(nftChain, version: .v2)
        return blockchain.displayName
    }
}
