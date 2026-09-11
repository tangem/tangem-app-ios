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
            ForEach(Array(Constants.arcs.enumerated()), id: \.offset) { _, arc in
                Circle()
                    .inset(by: Constants.lineWidth / 2)
                    .trim(from: arc.start / 360, to: arc.end / 360)
                    .stroke(arc.color, style: StrokeStyle(lineWidth: Constants.lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(size: Constants.size)
    }
}

// MARK: - Constants

private extension FeedPortfolioDonutView {
    enum Constants {
        static let size = CGSize(bothDimensions: 20)
        static let lineWidth: CGFloat = 5
        static let gapDegrees: CGFloat = 18
        static let segments: [(color: Color, sweepDegrees: CGFloat)] = [
            (DesignSystem.Color.iconAccentBlue, 150),
            (DesignSystem.Color.iconAccentRed, 40),
            (DesignSystem.Color.iconAccentGreen, 40),
            (DesignSystem.Color.iconAccentOrange, 40),
        ]

        static let arcs: [(color: Color, start: CGFloat, end: CGFloat)] = {
            let radius = (size.width - lineWidth) / 2
            let capDegrees = asin(lineWidth / 2 / radius) * 180 / .pi
            var cursor: CGFloat = 0

            return segments.map { segment in
                let start = cursor + capDegrees
                let end = max(cursor + segment.sweepDegrees - capDegrees, start + 0.5)
                cursor += segment.sweepDegrees + gapDegrees
                return (segment.color, start, end)
            }
        }()
    }
}
