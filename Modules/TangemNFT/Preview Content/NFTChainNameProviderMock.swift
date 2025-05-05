//
//  NFTChainNameProviderMock.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct NFTChainNameProviderMock: NFTChainNameProviding {
    func provide(for nftChain: NFTChain) -> String {
        "Ethereum"
    }
}
