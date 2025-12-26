//
//  NFTCollectionsListRoutable.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public protocol NFTCollectionsListRoutable: AnyObject {
    func receiveTapped()
    func openAssetDetails(
        for asset: NFTAsset,
        in collection: NFTCollection,
        navigationContext: NFTNavigationContext?
    )
}
