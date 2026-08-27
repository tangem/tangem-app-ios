//
//  GachaPackGrid+Skeleton.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension GachaPackGrid {
    struct Skeleton: View {
        let cellsCount: Int

        var body: some View {
            LazyVGrid(columns: Metrics.columns, alignment: .leading, spacing: Metrics.rowSpacing) {
                ForEach(0 ..< cellsCount, id: \.self) { _ in
                    GachaPackCard.Skeleton()
                }
            }
            .padding(.horizontal, Metrics.horizontalPadding)
        }
    }
}
