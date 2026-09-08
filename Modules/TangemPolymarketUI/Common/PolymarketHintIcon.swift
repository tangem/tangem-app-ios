//
//  PolymarketHintIcon.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct PolymarketHintIcon: View {
    let asset: ImageType

    var body: some View {
        asset.image
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: Constants.side))
            .foregroundStyle(DesignSystem.Color.iconTertiary)
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension PolymarketHintIcon {
    enum Constants {
        static let side: CGFloat = 16
    }
}
