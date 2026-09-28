//
//  CollectiblesMachineView+Skeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

extension CollectiblesMachineView {
    /// Mirrors `sections`: a heading bar and a chip grid per section, in the same layout the content lands in.
    struct Skeleton: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                section(chipsCount: Metrics.tierChipsCount)

                section(chipsCount: Metrics.detailChipsCount)
                    .padding(.top, CollectiblesMachineView.Metrics.sectionsGap)

                CollectiblesMachineView.PoweredBy()
                    .padding(.top, Metrics.poweredByTopPadding)
            }
            .padding(.horizontal, CollectiblesMachineView.Metrics.horizontalPadding)
        }
    }
}

private extension CollectiblesMachineView.Skeleton {
    // MARK: - View properties

    func section(chipsCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            headingBar
                .padding(.vertical, CollectiblesMachineView.Metrics.sectionHeaderVerticalPadding)

            chipGrid(count: chipsCount)
                .padding(.vertical, CollectiblesMachineView.Metrics.chipsContainerVerticalPadding)
        }
    }

    var headingBar: some View {
        Shimmer()
            .frame(width: Metrics.headingBarWidth, height: Metrics.headingBarHeight)
            .clipShape(Capsule())
            .frame(height: Metrics.headingLineHeight)
    }

    func chipGrid(count: Int) -> some View {
        LazyVGrid(
            columns: CollectiblesMachineView.Metrics.chipColumns,
            alignment: .leading,
            spacing: CollectiblesMachineView.Metrics.chipSpacing
        ) {
            ForEach(0 ..< count, id: \.self) { _ in
                Shimmer()
                    .frame(height: Metrics.chipHeight)
                    .clipShape(RoundedRectangle(cornerRadius: CollectiblesMachineView.Metrics.chipCornerRadius, style: .continuous))
            }
        }
    }
}

// MARK: - Metrics

private extension CollectiblesMachineView.Skeleton {
    enum Metrics {
        static let tierChipsCount = 4
        static let detailChipsCount = 2
        static let chipHeight: CGFloat = 72
        static let headingBarWidth: CGFloat = 101
        static let headingBarHeight: CGFloat = 12
        static let headingLineHeight: CGFloat = 18
        static let poweredByTopPadding: CGFloat = 4
    }
}
