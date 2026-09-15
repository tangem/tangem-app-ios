//
//  FeedPortfolioDonutView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct FeedPortfolioDonutView: View {
    var body: some View {
        ZStack {
            ring.stroke(DesignSystem.Color.paletteOpaqueBaseBlack20, lineWidth: Constants.lineWidth)
            ring.stroke(DesignSystem.Color.paletteOpaqueBaseWhite20, lineWidth: Constants.lineWidth)

            ForEach(Constants.arcs.indices, id: \.self) { index in
                ring
                    .trim(from: 0, to: Constants.arcs[index].sweep / 360)
                    .stroke(Constants.arcs[index].color, style: StrokeStyle(lineWidth: Constants.lineWidth, lineCap: .round))
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
