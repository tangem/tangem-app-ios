//
//  TokenSectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TokenSectionView: View {
    let title: String?
    let topEdgeCornerRadius: CGFloat?
    var backgroundColor: Color = Colors.Background.primary

    var body: some View {
        if let title = title {
            OrganizeTokensListInnerSectionView(title: title, isDraggable: false)
                .background(background)
        }
    }

    @ViewBuilder
    private var background: some View {
        if let topEdgeCornerRadius = topEdgeCornerRadius {
            backgroundColor.cornerRadiusContinuous(
                topLeadingRadius: topEdgeCornerRadius,
                topTrailingRadius: topEdgeCornerRadius
            )
        } else {
            backgroundColor
        }
    }
}

// MARK: - Previews

struct TokenSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TokenSectionView(title: "Ethereum", topEdgeCornerRadius: nil)

            TokenSectionView(title: nil, topEdgeCornerRadius: nil)

            TokenSectionView(title: "A token list section header view with an extremely long title...", topEdgeCornerRadius: nil)
        }
    }
}
