//
//  EarnMostlyUsedView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct EarnMostlyUsedView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Layout.cardSpacing) {
                ForEach(0 ..< 3) { _ in
                    placeholderTile
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .frame(height: Layout.height)
    }

    private var placeholderTile: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(Color.red)
            .frame(width: Layout.tileWidth, height: Layout.tileHeight)
    }
}

private extension EarnMostlyUsedView {
    enum Layout {
        static let height: CGFloat = 108.0
        static let cardSpacing: CGFloat = 8.0
        static let horizontalPadding: CGFloat = 16.0
        static let cornerRadius: CGFloat = 14.0
        static let tileWidth: CGFloat = 150.0
        static let tileHeight: CGFloat = 108.0
    }
}
