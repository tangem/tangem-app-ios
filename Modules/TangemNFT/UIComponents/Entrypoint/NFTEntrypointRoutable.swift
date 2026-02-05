//
//  NFTEntrypointRoutable.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol NFTEntrypointRoutable: AnyObject {
    func openCollections(
        nftManager: NFTManager,
        accountForNFTCollectionsProvider: any AccountForNFTCollectionsProviding,
        navigationContext: NFTNavigationContext
    )
}
