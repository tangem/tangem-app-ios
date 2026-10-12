//
//  CollectiblesPackGrid.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct CollectiblesPackGrid: View {
    let models: [CollectiblesPackCard.Model]
    var onLastItemAppear: (() -> Void)?
    var onSelect: ((CollectiblesPackCard.Model.ID) -> Void)?

    var body: some View {
        LazyVGrid(columns: Metrics.columns, alignment: .leading, spacing: Metrics.rowSpacing) {
            ForEach(models) { model in
                Button(action: { onSelect?(model.id) }) {
                    CollectiblesPackCard(model: model)
                }
                .buttonStyle(.defaultScaled)
                .onAppear {
                    if model.id == models.last?.id {
                        onLastItemAppear?()
                    }
                }
            }
        }
        .padding(.horizontal, Metrics.horizontalPadding)
    }
}

// MARK: - Metrics

/// Not private: `Skeleton` reads the shared values so the grid does not jump when the content arrives.
extension CollectiblesPackGrid {
    enum Metrics {
        static let columns = [
            GridItem(.flexible(), spacing: columnSpacing),
            GridItem(.flexible(), spacing: columnSpacing),
        ]

        static let columnSpacing: CGFloat = 12
        static let rowSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }
}
