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
    struct Skeleton: View {
        let columns = CollectiblesMachineView.Metrics.chipColumns
        let spacing = CollectiblesMachineView.Metrics.chipSpacing
        let horizontalPadding = CollectiblesMachineView.Metrics.horizontalPadding

        var body: some View {
            LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
                ForEach(0 ..< Metrics.chipsCount, id: \.self) { _ in
                    Shimmer()
                        .frame(height: Metrics.chipHeight)
                        .clipShape(RoundedRectangle(cornerRadius: CollectiblesMachineView.Metrics.chipCornerRadius, style: .continuous))
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
    }
}

// MARK: - Metrics

private extension CollectiblesMachineView.Skeleton {
    enum Metrics {
        static let chipsCount = 6
        static let chipHeight: CGFloat = 72
    }
}
