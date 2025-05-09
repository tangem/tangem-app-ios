//
//  NFTNetworkSelectionListDataSource.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol NFTNetworkSelectionListDataSource {
    func allSupportedChains() -> [NFTChainItem]

    func isSupportedChainAvailable(_ nftChainItem: NFTChainItem) -> Bool
}
