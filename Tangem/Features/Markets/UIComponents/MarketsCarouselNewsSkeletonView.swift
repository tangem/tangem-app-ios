//
//  MarketsCarouselNewsSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MarketsCarouselNewsSkeletonView: View {
    private let bleedInset: CGFloat = .unit(.x4)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .unit(.x3)) {
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

#if DEBUG
#Preview {
    MarketsCarouselNewsSkeletonView()
        .padding(.horizontal, .unit(.x4))
        .background(Color.Tangem.Surface.level2)
}
#endif // DEBUG
