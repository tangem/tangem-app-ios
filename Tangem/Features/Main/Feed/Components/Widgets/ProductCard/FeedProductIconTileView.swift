//
//  FeedProductIconTileView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct FeedProductIconTileView: View {
    let color: Color
    let showsHighlight: Bool
    let side: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: side * Constants.cornerRadiusRatio, style: .continuous)
        let scale = side / Constants.designSide

        shape.fill(color)
            .overlay {
                if showsHighlight {
                    shape.fill(LinearGradient(
                        colors: [DesignSystem.Color.paletteBaseWhite.opacity(0), DesignSystem.Color.paletteOpaqueBaseWhite20],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }
            }
            .shadow(color: color.opacity(0.2), radius: 18 * scale, y: 2 * scale)
            .shadow(color: color.opacity(0.12), radius: 2.5 * scale, y: 2 * scale)
            .frame(width: side, height: side)
    }
}

// MARK: - Constants

private extension FeedProductIconTileView {
    enum Constants {
        static let designSide: CGFloat = 40
        static let cornerRadiusRatio: CGFloat = 0.3
    }
}
