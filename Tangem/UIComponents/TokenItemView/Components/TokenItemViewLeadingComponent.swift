//
//  TokenItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenItemViewLeadingComponent: View {
    let name: String
    let imageURL: URL?
    let blockchainIconName: String?
    let hasMonochromeIcon: Bool
    let isCustom: Bool

    var body: some View {
        TokenIcon(
            name: name,
            imageURL: imageURL,
            blockchainIconName: blockchainIconName,
            isCustom: isCustom,
            size: .init(bothDimensions: 36.0)
        )
        .saturation(hasMonochromeIcon ? 0 : 1)
    }
}
