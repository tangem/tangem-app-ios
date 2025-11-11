//
//  NFTChainIconProviderMock.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets

struct NFTChainIconProviderMock: NFTChainIconProvider {
    func provide(by nftChain: NFTChain) -> ImageType {
        Assets.star
    }
}
