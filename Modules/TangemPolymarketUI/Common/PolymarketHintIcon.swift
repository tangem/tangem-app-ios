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
    var side: CGFloat = Constants.side

    var body: some View {
        asset.image
            .renderingMode(.template)
            .resizable()
            .frame(size: .init(bothDimensions: side))
            .foregroundStyle(DesignSystem.Color.iconTertiary)
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

extension PolymarketHintIcon {
    enum Constants {
        static let side: CGFloat = 16
        static let selectSide: CGFloat = 20
    }
}
