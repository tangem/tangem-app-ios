//
//  NFTCompactAssetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT
import Foundation
import BlockchainSdk

final class NFTCompactAssetViewModel {
    private let nftAsset: NFTAsset

    init(nftAsset: NFTAsset) {
        self.nftAsset = nftAsset
    }

    var id: String {
        nftAsset.id.assetIdentifier
    }

    var mediaURL: URL? {
        nftAsset.media?.url
    }

    var name: String {
        nftAsset.name
    }
}
