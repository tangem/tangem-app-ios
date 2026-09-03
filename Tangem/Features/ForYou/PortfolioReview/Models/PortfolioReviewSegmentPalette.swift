//
//  PortfolioReviewSegmentPalette.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

/// The donut's colours, shared with the token rows so a row's dot and its slice can't drift apart.
enum PortfolioReviewSegmentPalette {
    /// The bucket's dot on its row: a plain neutral marker, never one of the ranked shades.
    static let otherIndicatorColor = DesignSystem.Color.borderAccentNeutral

    /// The bucket's arc keeps the ring's own grey, so it reads as the plate it replaces.
    static let otherArcColor = DesignSystem.Color.borderPrimary

    /// Each ranked id takes the slice of its rank; the palette has to cover the whole top, ids past it get none.
    static func slices(forRanked ids: [String]) -> [String: Slice] {
        var slicesByID: [String: Slice] = [:]

        for (rank, id) in ids.prefix(Slice.all.count).enumerated() {
            slicesByID[id] = Slice.all[rank]
        }

        return slicesByID
    }
}

extension PortfolioReviewSegmentPalette {
    struct Slice {
        let arc, indicator: Color
    }
}

private extension PortfolioReviewSegmentPalette.Slice {
    /// One shade per rank in the mockup's order: the six accents, then their pastels.
    static let all: [PortfolioReviewSegmentPalette.Slice] = [
        .single(DesignSystem.Color.borderBrand),
        .single(DesignSystem.Color.iconAccentGreen),
        .single(DesignSystem.Color.iconAccentYellow),
        .single(DesignSystem.Color.iconAccentRed),
        .single(DesignSystem.Color.iconAccentViolet),
        .single(DesignSystem.Color.iconAccentOrange),
        .single(DesignSystem.Color.paletteBlue30),
        .single(DesignSystem.Color.paletteGreen30),
        .single(DesignSystem.Color.paletteYellow20),
        .single(DesignSystem.Color.paletteRed30),
    ]

    static func single(_ color: Color) -> Self {
        .init(arc: color, indicator: color)
    }
}
