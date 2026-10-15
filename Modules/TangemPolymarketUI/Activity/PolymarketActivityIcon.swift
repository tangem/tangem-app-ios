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

    var body: some View {
        switch icon {
        case .market(let url):
            PolymarketAvatarView(url: url, side: Constants.side)
        case .glyph(let image):
            image.image
                .renderingMode(.template)
                .resizable()
                .frame(width: Constants.glyphSide, height: Constants.glyphSide)
                .foregroundStyle(DesignSystem.Color.iconPrimary)
                .frame(width: Constants.side, height: Constants.side)
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
