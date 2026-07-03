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
            HStack(spacing: .unit(.x3)) {
                iconPlaceholder

                makeSkeletonsStack(alignment: .leading)
            }

            Spacer()

            makeSkeletonsStack(alignment: .trailing)
        }
        .padding(.unit(.x3))
        .background(Color.Tangem.Surface.level3)
        .cornerRadiusContinuous(.unit(.x5))
        .environment(\.isSkeletonShimmerActive, isShimmerActive)
    }

    private var iconPlaceholder: some View {
        SkeletonView()
            .frame(size: CGSize(bothDimensions: iconDimension))
            .clipShape(Circle())
    }

    private func makeSkeletonsStack(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: .unit(.x1_5)) {
            SkeletonView()
                .frame(size: CGSize(width: 80, height: 16) * scaleFactor)
                .clipShape(Capsule(style: .continuous))

            SkeletonView()
                .frame(size: CGSize(width: 42, height: 12) * scaleFactor)
                .clipShape(Capsule(style: .continuous))
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

#if DEBUG
#Preview {
    ZStack {
        Color.Tangem.Surface.level2
            .ignoresSafeArea()

        VStack(spacing: .unit(.x2)) {
            RedesignedAccountSkeletonCardView()
            RedesignedAccountSkeletonCardView()
            RedesignedAccountSkeletonCardView()
        }
        .padding(.horizontal, .unit(.x3))
    }
}
#endif
