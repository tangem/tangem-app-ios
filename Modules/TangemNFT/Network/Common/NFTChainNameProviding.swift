//
//  NFTChainNameProviding.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol NFTChainNameProviding {
    func provide(for nftChain: NFTChain) -> String
}
