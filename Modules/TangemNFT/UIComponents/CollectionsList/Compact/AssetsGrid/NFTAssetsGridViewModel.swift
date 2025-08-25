//
//  NFTAssetsGridViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct NFTAssetsGridViewModel {
    let assetsViewModels: [NFTCompactAssetViewModel]
}

// MARK: - Convenience extensions

extension NFTAssetsGridViewModel {
    /// Use this convenience init to create a view model with the specified number of loading assets.
    init(assetsCount: Int) {
        let assetsViewModels = (0 ..< assetsCount).map {
            NFTCompactAssetViewModel(state: .loading(id: "\($0)"), openAssetDetailsAction: { _ in })
        }

        self.init(assetsViewModels: assetsViewModels)
    }
}
