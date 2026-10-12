//
//  RealAssetsCategoryFilterInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct RealAssetsCategoryFilterInput {
    let categories: [MarketsDTO.Categories.Category]
    let selection: RealAssetsCategorySelection
    let defaultSelection: RealAssetsCategorySelection
    let onApply: (RealAssetsCategorySelection) -> Void
}
