//
//  FeedPortfolioDonutView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct FeedPortfolioDonutView: View {
    var body: some View {
        ZStack {
            ring.stroke(DesignSystem.Color.paletteOpaqueBaseBlack20, lineWidth: Constants.lineWidth)
            ring.stroke(DesignSystem.Color.paletteOpaqueBaseWhite20, lineWidth: Constants.lineWidth)

            ForEach(indexed: Constants.arcs, id: \.0) { _, arc in
                ring
                    .trim(from: 0, to: arc.sweep / 360)
                    .stroke(arc.color, style: StrokeStyle(lineWidth: Constants.lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(size: CGSize(bothDimensions: Constants.side))
    }
}

// MARK: - Subviews

private extension FeedPortfolioDonutView {
    var ring: some InsettableShape {
        Circle().inset(by: (Constants.side - Constants.ringDiameter) / 2)
    }
}

// MARK: - Constants

private extension FeedPortfolioDonutView {
    enum Constants {
        static let side: CGFloat = 24
        static let ringDiameter: CGFloat = 20.16
        static let lineWidth: CGFloat = 5.84
        static let arcs: [(color: Color, sweep: CGFloat)] = [
            (DesignSystem.Color.iconAccentGreen, 280.8),
            (DesignSystem.Color.iconAccentRed, 251.78),
            (DesignSystem.Color.iconAccentViolet, 201.17),
            (DesignSystem.Color.iconBrand, 152.86),
        ]
    }
}
