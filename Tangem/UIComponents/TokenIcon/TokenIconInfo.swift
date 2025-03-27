//
//  TokenIcon.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// [REDACTED_TODO_COMMENT]
struct TokenIconInfo: Hashable {
    let name: String
    let blockchainIconAsset: ImageType?
    let imageURL: URL?
    let isCustom: Bool
    let customTokenColor: Color?
    let networkBorderColor: Color

    init(
        name: String,
        blockchainIconAsset: ImageType?,
        imageURL: URL?,
        isCustom: Bool,
        customTokenColor: Color?,
        networkBorderColor: Color = Colors.Background.primary
    ) {
        self.name = name
        self.blockchainIconAsset = blockchainIconAsset
        self.imageURL = imageURL
        self.isCustom = isCustom
        self.customTokenColor = customTokenColor
        self.networkBorderColor = networkBorderColor
    }
}
