//
//  NFTCompactAssetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class NFTCompactAssetViewModel: Identifiable {
    private let nftAsset: NFTAsset
    private let openAssetDetailsAction: (NFTAsset) -> Void

    init(nftAsset: NFTAsset, openAssetDetailsAction: @escaping (NFTAsset) -> Void) {
        self.nftAsset = nftAsset
        self.openAssetDetailsAction = openAssetDetailsAction
    }

    var id: String {
        nftAsset.id.assetIdentifier
    }

    var mediaURL: URL? {
        nftAsset.media?.url
    }

    var title: String {
        nftAsset.name
    }

    var subtitle: String {
        "0.15 ETH" // Price should be taken from somewhere
    }

    func didClick() {
        openAssetDetailsAction(nftAsset)
    }
}
