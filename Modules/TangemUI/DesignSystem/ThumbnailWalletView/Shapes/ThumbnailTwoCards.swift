//
//  ThumbnailTwoCards.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

typealias ThumbnailTwoCardsView = ThumbnailPathBuilderView<ThumbnailTwoCardsPathBuilder>

public enum ThumbnailTwoCardsPathBuilder: ThumbnailPathBuilding {
    public struct FillColors: Equatable {
        public let card: Color
        public let secondCard: Color

        public init(card: Color, secondCard: Color) {
            self.card = card
            self.secondCard = secondCard
        }
    }

    /// All Path manipulations below are SVG to SwiftUI conversion
    static func build(
        for size: CGSize,
        with colors: FillColors,
        colorScheme: ColorScheme
    ) -> [ThumbnailPathFillMode] {
        var path = Path()
        var result: [ThumbnailPathFillMode] = []
        let width = size.width
        let height = size.height

        path.move(to: CGPoint(x: 0.08333 * width, y: 0.40833 * height))
        path.addCurve(to: CGPoint(x: 0.09696 * width, y: 0.27658 * height), control1: CGPoint(x: 0.08333 * width, y: 0.33833 * height), control2: CGPoint(x: 0.08333 * width, y: 0.30332 * height))
        path.addCurve(to: CGPoint(x: 0.15158 * width, y: 0.22196 * height), control1: CGPoint(x: 0.10894 * width, y: 0.25306 * height), control2: CGPoint(x: 0.12806 * width, y: 0.23394 * height))
        path.addCurve(to: CGPoint(x: 0.28333 * width, y: 0.20833 * height), control1: CGPoint(x: 0.17832 * width, y: 0.20833 * height), control2: CGPoint(x: 0.21333 * width, y: 0.20833 * height))
        path.addLine(to: CGPoint(x: 0.63333 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.76508 * width, y: 0.22196 * height), control1: CGPoint(x: 0.70334 * width, y: 0.20833 * height), control2: CGPoint(x: 0.73834 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.81971 * width, y: 0.27658 * height), control1: CGPoint(x: 0.7886 * width, y: 0.23394 * height), control2: CGPoint(x: 0.80773 * width, y: 0.25306 * height))
        path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.40833 * height), control1: CGPoint(x: 0.83333 * width, y: 0.30332 * height), control2: CGPoint(x: 0.83333 * width, y: 0.33833 * height))
        path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.59167 * height))
        path.addCurve(to: CGPoint(x: 0.81971 * width, y: 0.72342 * height), control1: CGPoint(x: 0.83333 * width, y: 0.66168 * height), control2: CGPoint(x: 0.83333 * width, y: 0.69667 * height))
        path.addCurve(to: CGPoint(x: 0.76508 * width, y: 0.77804 * height), control1: CGPoint(x: 0.80773 * width, y: 0.74694 * height), control2: CGPoint(x: 0.7886 * width, y: 0.76606 * height))
        path.addCurve(to: CGPoint(x: 0.63333 * width, y: 0.79167 * height), control1: CGPoint(x: 0.73834 * width, y: 0.79167 * height), control2: CGPoint(x: 0.70334 * width, y: 0.79167 * height))
        path.addLine(to: CGPoint(x: 0.28333 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.15158 * width, y: 0.77804 * height), control1: CGPoint(x: 0.21333 * width, y: 0.79167 * height), control2: CGPoint(x: 0.17832 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.09696 * width, y: 0.72342 * height), control1: CGPoint(x: 0.12806 * width, y: 0.76606 * height), control2: CGPoint(x: 0.10894 * width, y: 0.74694 * height))
        path.addCurve(to: CGPoint(x: 0.08333 * width, y: 0.59167 * height), control1: CGPoint(x: 0.08333 * width, y: 0.69667 * height), control2: CGPoint(x: 0.08333 * width, y: 0.66168 * height))
        path.addLine(to: CGPoint(x: 0.08333 * width, y: 0.40833 * height))
        path.closeSubpath()
        result.append(
            .fill(
                path: path,
                fillColor: colors.card,
                stroke: colorScheme.stroke(width: width * 0.03)
            )
        )
        path = Path()

        path.move(to: CGPoint(x: 0.7306 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.86691 * width, y: 0.22196 * height), control1: CGPoint(x: 0.80302 * width, y: 0.20833 * height), control2: CGPoint(x: 0.83925 * width, y: 0.20834 * height))
        path.addCurve(to: CGPoint(x: 0.9234 * width, y: 0.27657 * height), control1: CGPoint(x: 0.89123 * width, y: 0.23395 * height), control2: CGPoint(x: 0.911 * width, y: 0.25306 * height))
        path.addCurve(to: CGPoint(x: 0.9375 * width, y: 0.40832 * height), control1: CGPoint(x: 0.93749 * width, y: 0.30331 * height), control2: CGPoint(x: 0.9375 * width, y: 0.33832 * height))
        path.addLine(to: CGPoint(x: 0.9375 * width, y: 0.59168 * height))
        path.addCurve(to: CGPoint(x: 0.9234 * width, y: 0.72343 * height), control1: CGPoint(x: 0.9375 * width, y: 0.66168 * height), control2: CGPoint(x: 0.93749 * width, y: 0.69669 * height))
        path.addCurve(to: CGPoint(x: 0.86691 * width, y: 0.77804 * height), control1: CGPoint(x: 0.911 * width, y: 0.74694 * height), control2: CGPoint(x: 0.89123 * width, y: 0.76605 * height))
        path.addCurve(to: CGPoint(x: 0.7306 * width, y: 0.79167 * height), control1: CGPoint(x: 0.83925 * width, y: 0.79166 * height), control2: CGPoint(x: 0.80302 * width, y: 0.79167 * height))
        path.addLine(to: CGPoint(x: 0.6875 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.8238 * width, y: 0.77804 * height), control1: CGPoint(x: 0.75992 * width, y: 0.79167 * height), control2: CGPoint(x: 0.79614 * width, y: 0.79166 * height))
        path.addCurve(to: CGPoint(x: 0.88029 * width, y: 0.72343 * height), control1: CGPoint(x: 0.84813 * width, y: 0.76605 * height), control2: CGPoint(x: 0.8679 * width, y: 0.74694 * height))
        path.addCurve(to: CGPoint(x: 0.8944 * width, y: 0.59168 * height), control1: CGPoint(x: 0.89439 * width, y: 0.69669 * height), control2: CGPoint(x: 0.8944 * width, y: 0.66168 * height))
        path.addLine(to: CGPoint(x: 0.8944 * width, y: 0.40832 * height))
        path.addCurve(to: CGPoint(x: 0.88029 * width, y: 0.27657 * height), control1: CGPoint(x: 0.8944 * width, y: 0.33832 * height), control2: CGPoint(x: 0.89439 * width, y: 0.30331 * height))
        path.addCurve(to: CGPoint(x: 0.8238 * width, y: 0.22196 * height), control1: CGPoint(x: 0.8679 * width, y: 0.25306 * height), control2: CGPoint(x: 0.84813 * width, y: 0.23395 * height))
        path.addCurve(to: CGPoint(x: 0.6875 * width, y: 0.20833 * height), control1: CGPoint(x: 0.79614 * width, y: 0.20834 * height), control2: CGPoint(x: 0.75992 * width, y: 0.20833 * height))
        path.addLine(to: CGPoint(x: 0.7306 * width, y: 0.20833 * height))
        path.closeSubpath()
        result.append(.fill(path: path, fillColor: colors.secondCard))

        return result
    }
}
