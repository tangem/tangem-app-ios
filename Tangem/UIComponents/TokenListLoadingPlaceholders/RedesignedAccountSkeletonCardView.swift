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

struct RedesignedAccountSkeletonCardView: View {
    @ScaledMetric private var iconDimension: CGFloat = 36
    @ScaledSize private var topLineSize = CGSize(width: 80, height: 16)
    @ScaledSize private var bottomLineSize = CGSize(width: 42, height: 12)

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
        .background(Color.Tangem.Surface.level1)
        .cornerRadiusContinuous(.unit(.x5))
    }

    private var iconPlaceholder: some View {
        SkeletonView()
            .frame(size: CGSize(bothDimensions: iconDimension))
            .clipShape(Circle())
    }

    private func makeSkeletonsStack(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: .unit(.x1_5)) {
            SkeletonView()
                .frame(size: topLineSize)
                .clipShape(Capsule(style: .continuous))

            SkeletonView()
                .frame(size: bottomLineSize)
                .clipShape(Capsule(style: .continuous))
        }
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
