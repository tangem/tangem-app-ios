//
//  EarnTokenTileSkeletonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct EarnTokenTileSkeletonView: View {
    @ScaledMetric private var iconSize: CGFloat = SizeUnit.x10.value
    @ScaledMetric private var nameWidth: CGFloat = 95
    @ScaledMetric private var nameHeight: CGFloat = 20
    @ScaledMetric private var rateWidth: CGFloat = 50
    @ScaledMetric private var rateHeight: CGFloat = 16
    @ScaledMetric private var tileWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            SkeletonView()
                .frame(width: iconSize, height: iconSize)
                .cornerRadius(iconSize / 2)

            FixedSpacer(height: .unit(.x6))

            SkeletonView()
                .frame(width: nameWidth, height: nameHeight)
                .cornerRadius(nameHeight / 2)

            FixedSpacer(height: .unit(.x1))

            SkeletonView()
                .frame(width: rateWidth, height: rateHeight)
                .cornerRadius(rateHeight / 2)
        }
        .frame(width: tileWidth, alignment: .topLeading)
        .padding(.bottom, .unit(.x1))
        .defaultRoundedBackground(
            with: Color.Tangem.Surface.level3,
            cornerRadius: .unit(.x5)
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#if DEBUG
#Preview {
    HStack(spacing: .unit(.x2)) {
        EarnTokenTileSkeletonView()
        EarnTokenTileSkeletonView()
        EarnTokenTileSkeletonView()
    }
    .padding()
}
#endif // DEBUG
