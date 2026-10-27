//
//  RedesignedAccountSkeletonCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct RedesignedAccountSkeletonCardView: View {
    @ScaledMetric private var scaleFactor: CGFloat = 1
    @ScaledMetric private var iconDimension: CGFloat = 36

    private var isShimmerActive: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                iconPlaceholder

                makeSkeletonsStack(alignment: .leading)
            }

            Spacer()

            makeSkeletonsStack(alignment: .trailing)
        }
        .padding(12)
        .background(DesignSystem.Color.bgSecondary)
        .cornerRadiusContinuous(24)
        .environment(\.isShimmerAnimationPaused, !isShimmerActive)
    }

    private var iconPlaceholder: some View {
        Shimmer().variant(.custom(width: iconDimension, height: iconDimension))
    }

    private func makeSkeletonsStack(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            Shimmer().variant(.custom(width: 80 * scaleFactor, height: 16 * scaleFactor))

            Shimmer().variant(.custom(width: 42 * scaleFactor, height: 12 * scaleFactor))
        }
    }
}

// MARK: - Setupable

extension RedesignedAccountSkeletonCardView: Setupable {
    func setShimmerActive(_ isShimmerActive: Bool) -> Self {
        map { $0.isShimmerActive = isShimmerActive }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        DesignSystem.Color.bgPrimary
            .ignoresSafeArea()

        VStack(spacing: 8) {
            RedesignedAccountSkeletonCardView()
            RedesignedAccountSkeletonCardView()
            RedesignedAccountSkeletonCardView()
        }
        .padding(.horizontal, 12)
    }
}
