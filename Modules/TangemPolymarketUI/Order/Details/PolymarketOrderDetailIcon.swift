//
//  PolymarketOrderDetailIcon.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct PolymarketOrderDetailIcon: View {
    let asset: ImageType

    var body: some View {
        asset.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Constants.side, height: Constants.side)
            .foregroundStyle(DesignSystem.Color.iconTertiary)
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension PolymarketOrderDetailIcon {
    enum Constants {
        static let side: CGFloat = 16
    }
}
