//
//  PolymarketActivityIcon.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PolymarketActivityIcon: View {
    let icon: PolymarketActivityRow.Icon
    var side: CGFloat = Constants.side
    var glyphSide: CGFloat = Constants.glyphSide

    var body: some View {
        switch icon {
        case .market(let url):
            PolymarketAvatarView(url: url, side: side)
        case .glyph(let image):
            image.image
                .renderingMode(.template)
                .resizable()
                .frame(width: glyphSide, height: glyphSide)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(width: side, height: side)
                .background(DesignSystem.Color.bgTertiary, in: Circle())
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Constants

private extension PolymarketActivityIcon {
    enum Constants {
        static let side: CGFloat = 40
        static let glyphSide: CGFloat = 20
    }
}
