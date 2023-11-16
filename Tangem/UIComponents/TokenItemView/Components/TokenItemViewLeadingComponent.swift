//
//  TokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct TokenItemViewLeadingComponent: View {
    let name: String
    let imageURL: URL?
    let customTokenColor: Color?
    let blockchainIconName: String?
    let hasMonochromeIcon: Bool
    let isCustom: Bool

    var body: some View {
        TokenIcon(
            tokenIconInfo: .init(
                blockchainIconName: blockchainIconName,
                imageURL: imageURL,
                isCustom: isCustom,
                customTokenColor: customTokenColor
            ),
            size: .init(bothDimensions: 36.0)
        )
        .saturation(hasMonochromeIcon ? 0 : 1)
    }
}
