//
//  EarnTokenTileSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnTokenTileSkeletonView: View {
    @ScaledMetric private var tileWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Shimmer()
                .variant(.custom(width: 40, height: 40))

            FixedSpacer(height: 24)

            Shimmer()
                .variant(.custom(width: 95, height: 20))

            FixedSpacer(height: 4)

            Shimmer()
                .variant(.custom(width: 50, height: 16))
        }
        .frame(width: tileWidth, alignment: .topLeading)
        .padding(.bottom, 4)
        .defaultRoundedBackground(
            with: DesignSystem.Color.bgSecondary,
            cornerRadius: 24
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview {
    HStack(spacing: 8) {
        EarnTokenTileSkeletonView()
        EarnTokenTileSkeletonView()
        EarnTokenTileSkeletonView()
    }
    .padding()
}
