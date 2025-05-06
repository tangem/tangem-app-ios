//
//  NFTAssetsGridViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct NFTAssetsGridViewModel {
    let assetsViewModels: [NFTCompactAssetViewModel]

    init(assetsViewModels: [NFTCompactAssetViewModel]) {
        self.assetsViewModels = assetsViewModels
    }
}
