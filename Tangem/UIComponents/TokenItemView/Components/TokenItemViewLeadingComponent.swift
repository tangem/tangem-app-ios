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
    let tokenIconInfo: TokenIconInfo
    let hasMonochromeIcon: Bool

    var body: some View {
        TokenIcon(
            tokenIconInfo: tokenIconInfo,
            size: .init(bothDimensions: 36.0)
        )
        .saturation(hasMonochromeIcon ? 0 : 1)
    }
}

extension TokenItemViewLeadingComponent {
    init(from tokenItemViewModel: TokenItemViewModel, networkBorderColor: Color = Colors.Background.primary) {
        self.init(
            tokenIconInfo: .init(
                name: tokenItemViewModel.name,
                blockchainIconAsset: tokenItemViewModel.blockchainIconAsset,
                imageURL: tokenItemViewModel.imageURL,
                isCustom: tokenItemViewModel.isCustom,
                customTokenColor: tokenItemViewModel.customTokenColor,
                networkBorderColor: networkBorderColor
            ),
            hasMonochromeIcon: tokenItemViewModel.hasMonochromeIcon,
        )
    }

    init(
        name: String,
        imageURL: URL?,
        customTokenColor: Color?,
        blockchainIconAsset: ImageType?,
        hasMonochromeIcon: Bool,
        isCustom: Bool,
        networkBorderColor: Color = Colors.Background.primary
    ) {
        self.init(
            tokenIconInfo: .init(
                name: name,
                blockchainIconAsset: blockchainIconAsset,
                imageURL: imageURL,
                isCustom: isCustom,
                customTokenColor: customTokenColor,
                networkBorderColor: networkBorderColor
            ),
            hasMonochromeIcon: hasMonochromeIcon,
        )
    }
}
