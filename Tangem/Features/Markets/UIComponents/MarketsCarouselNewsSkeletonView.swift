//
//  MarketsCarouselNewsSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsCarouselNewsSkeletonView: View {
    private let bleedInset: CGFloat = 16

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CarouselNewsCardSkeletonView()
                CarouselNewsCardSkeletonView()
            }
            .padding(.horizontal, bleedInset)
        }
        .scrollDisabled(true)
        .padding(.horizontal, -bleedInset)
    }
}

// MARK: - Previews

#Preview {
    MarketsCarouselNewsSkeletonView()
        .padding(.horizontal, 16)
        .background(DesignSystem.Color.bgPrimary)
}
