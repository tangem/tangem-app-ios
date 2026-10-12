//
//  PolymarketPositionStatsGrid.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct PolymarketPositionStatsGrid: View {
    private let tiles: [PolymarketPositionStatTile.Model]

    public init(tiles: [PolymarketPositionStatTile.Model]) {
        self.tiles = tiles
    }

    public var body: some View {
        LazyVGrid(columns: Constants.columns, spacing: Constants.spacing) {
            ForEach(tiles) { tile in
                PolymarketPositionStatTile(model: tile)
            }
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionStatsGrid {
    enum Constants {
        static let spacing: CGFloat = 8

        static let columns = [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing),
        ]
    }
}
