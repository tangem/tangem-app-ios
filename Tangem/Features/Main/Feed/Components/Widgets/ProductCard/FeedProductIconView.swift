//
//  FeedProductIconView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct FeedProductIconView: View {
    let appearance: FeedProductCardView.Appearance

    @ScaledMetric private var tileSide: CGFloat = Constants.tileSide
    @ScaledMetric private var iconWidth: CGFloat
    @ScaledMetric private var iconHeight: CGFloat

    init(appearance: FeedProductCardView.Appearance) {
        self.appearance = appearance
        _iconWidth = ScaledMetric(wrappedValue: appearance.iconSize.width)
        _iconHeight = ScaledMetric(wrappedValue: appearance.iconSize.height)
    }

    var body: some View {
        appearance.icon
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(DesignSystem.Color.iconStaticDark)
            .opacity(appearance.iconOpacity)
            .frame(width: iconWidth, height: iconHeight)
            .frame(size: CGSize(bothDimensions: tileSide))
            .background {
                FeedProductIconTileView(color: appearance.color, showsHighlight: appearance.showsHighlight, side: tileSide)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Constants

private extension FeedProductIconView {
    enum Constants {
        static let tileSide: CGFloat = 40
    }
}
