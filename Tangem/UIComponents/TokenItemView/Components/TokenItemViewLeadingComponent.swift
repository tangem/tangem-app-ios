//
//  TokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemUI

struct TokenItemViewLeadingComponent: View {
    let name: String
    let imageURL: URL?
    let customTokenColor: Color?
    let blockchainIconAsset: ImageType?
    let hasMonochromeIcon: Bool
    let isCustom: Bool
    let networkBorderColor: Color

    init(
        name: String,
        imageURL: URL?,
        customTokenColor: Color?,
        blockchainIconAsset: ImageType?,
        hasMonochromeIcon: Bool,
        isCustom: Bool,
        networkBorderColor: Color = Colors.Background.primary
    ) {
        self.name = name
        self.imageURL = imageURL
        self.customTokenColor = customTokenColor
        self.blockchainIconAsset = blockchainIconAsset
        self.hasMonochromeIcon = hasMonochromeIcon
        self.isCustom = isCustom
        self.networkBorderColor = networkBorderColor
    }

    var body: some View {
        TokenIcon(
            tokenIconInfo: .init(
                name: name,
                blockchainIconAsset: blockchainIconAsset,
                imageURL: imageURL,
                isCustom: isCustom,
                customTokenColor: customTokenColor,
                networkBorderColor: networkBorderColor
            ),
            size: .init(bothDimensions: 36.0)
        )
        .saturation(hasMonochromeIcon ? 0 : 1)
    }
}

extension TokenItemViewLeadingComponent {
    init(from tokenItemViewModel: TokenItemViewModel, networkBorderColor: Color = Colors.Background.primary) {
        name = tokenItemViewModel.name
        imageURL = tokenItemViewModel.imageURL
        customTokenColor = tokenItemViewModel.customTokenColor
        blockchainIconAsset = tokenItemViewModel.blockchainIconAsset
        hasMonochromeIcon = tokenItemViewModel.hasMonochromeIcon
        isCustom = tokenItemViewModel.isCustom
        self.networkBorderColor = networkBorderColor
    }
}
