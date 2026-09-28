//
//  CollectiblesPrizeGrid.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct CollectiblesPrizeGrid: View {
    let models: [CollectiblesPrizeCard.Model]
    var onLastItemAppear: (() -> Void)?

    var body: some View {
        LazyVGrid(columns: Metrics.columns, alignment: .leading, spacing: Metrics.rowSpacing) {
            ForEach(models) { model in
                CollectiblesPrizeCard(model: model)
                    .onAppear {
                        if model.id == models.last?.id {
                            onLastItemAppear?()
                        }
                    }
            }
        }
    }
}

// MARK: - Metrics

/// Not private: `Skeleton` reads the shared values so the grid does not jump when the content arrives.
extension CollectiblesPrizeGrid {
    enum Metrics {
        static let columns = [
            GridItem(.flexible(), spacing: columnSpacing),
            GridItem(.flexible(), spacing: columnSpacing),
        ]

        static let columnSpacing: CGFloat = 12
        static let rowSpacing: CGFloat = 16
    }
}
