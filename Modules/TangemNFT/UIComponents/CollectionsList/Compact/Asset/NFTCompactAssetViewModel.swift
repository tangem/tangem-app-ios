//
//  NFTCompactAssetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NFTCompactAssetViewModel: Identifiable {
    private let nftAsset: NFTAsset
    private let openAssetDetailsAction: (NFTAsset) -> Void

    init(nftAsset: NFTAsset, openAssetDetailsAction: @escaping (NFTAsset) -> Void) {
        self.nftAsset = nftAsset
        self.openAssetDetailsAction = openAssetDetailsAction
    }

    var id: AnyHashable {
        nftAsset.id
    }

    var media: NFTMedia? {
        nftAsset.media
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
