//
//  ThumbnailLetterThreeCards.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

typealias ThumbnailLetterThreeCardsView = ThumbnailPathBuilderView<ThumbnailLetterThreeCardsPathBuilder>

public enum ThumbnailLetterThreeCardsPathBuilder: ThumbnailPathBuilding {
    public struct FillColors {
        public let card: Color
        public let secondCard: Color
        public let thirdCard: Color
        public let tLetter: Color

        public init(card: Color, secondCard: Color, thirdCard: Color, tLetter: Color) {
            self.card = card
            self.secondCard = secondCard
            self.thirdCard = thirdCard
            self.tLetter = tLetter
        }
    }

    /// All Path manipulations below are SVG to SwiftUI conversion
    static func build(
        for size: CGSize,
        with colors: FillColors,
        colorScheme: ColorScheme
    ) -> [ThumbnailPathFillMode] {
        var result: [ThumbnailPathFillMode] = []
        var path = Path()
        let width = size.width
        let height = size.height

        path.move(to: CGPoint(x: 0, y: 0.40833 * height))
        path.addCurve(to: CGPoint(x: 0.01362 * width, y: 0.27658 * height), control1: CGPoint(x: 0, y: 0.33833 * height), control2: CGPoint(x: 0, y: 0.30332 * height))
        path.addCurve(to: CGPoint(x: 0.06825 * width, y: 0.22196 * height), control1: CGPoint(x: 0.02561 * width, y: 0.25306 * height), control2: CGPoint(x: 0.04473 * width, y: 0.23394 * height))
        path.addCurve(to: CGPoint(x: 0.2 * width, y: 0.20833 * height), control1: CGPoint(x: 0.09499 * width, y: 0.20833 * height), control2: CGPoint(x: 0.12999 * width, y: 0.20833 * height))
        path.addLine(to: CGPoint(x: 0.55 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.68175 * width, y: 0.22196 * height), control1: CGPoint(x: 0.62001 * width, y: 0.20833 * height), control2: CGPoint(x: 0.65501 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.73637 * width, y: 0.27658 * height), control1: CGPoint(x: 0.70527 * width, y: 0.23394 * height), control2: CGPoint(x: 0.72439 * width, y: 0.25306 * height))
        path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.40833 * height), control1: CGPoint(x: 0.75 * width, y: 0.30332 * height), control2: CGPoint(x: 0.75 * width, y: 0.33833 * height))
        path.addLine(to: CGPoint(x: 0.75 * width, y: 0.59167 * height))
        path.addCurve(to: CGPoint(x: 0.73637 * width, y: 0.72342 * height), control1: CGPoint(x: 0.75 * width, y: 0.66168 * height), control2: CGPoint(x: 0.75 * width, y: 0.69667 * height))
        path.addCurve(to: CGPoint(x: 0.68175 * width, y: 0.77804 * height), control1: CGPoint(x: 0.72439 * width, y: 0.74694 * height), control2: CGPoint(x: 0.70527 * width, y: 0.76606 * height))
        path.addCurve(to: CGPoint(x: 0.55 * width, y: 0.79167 * height), control1: CGPoint(x: 0.65501 * width, y: 0.79167 * height), control2: CGPoint(x: 0.62001 * width, y: 0.79167 * height))
        path.addLine(to: CGPoint(x: 0.2 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.06825 * width, y: 0.77804 * height), control1: CGPoint(x: 0.12999 * width, y: 0.79167 * height), control2: CGPoint(x: 0.09499 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.01362 * width, y: 0.72342 * height), control1: CGPoint(x: 0.04473 * width, y: 0.76606 * height), control2: CGPoint(x: 0.02561 * width, y: 0.74694 * height))
        path.addCurve(to: CGPoint(x: 0, y: 0.59167 * height), control1: CGPoint(x: 0, y: 0.69667 * height), control2: CGPoint(x: 0, y: 0.66168 * height))
        path.addLine(to: CGPoint(x: 0, y: 0.40833 * height))
        path.closeSubpath()

        result.append(
            .fill(
                path: path,
                fillColor: colors.card,
                stroke: colorScheme.stroke(width: width * 0.03)
            )
        )
        path = Path()

        path.move(to: CGPoint(x: 0.33674 * width, y: 0.66667 * height))
        path.addLine(to: CGPoint(x: 0.33674 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.25 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.25 * width, y: 0.33333 * height))
        path.addLine(to: CGPoint(x: 0.5 * width, y: 0.33333 * height))
        path.addLine(to: CGPoint(x: 0.5 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.41305 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.41305 * width, y: 0.66667 * height))
        path.addLine(to: CGPoint(x: 0.33674 * width, y: 0.66667 * height))
        path.closeSubpath()
        result.append(
            .fill(path: path, fillColor: colors.tLetter)
        )
        path = Path()

        path.move(to: CGPoint(x: 0.6681 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.80441 * width, y: 0.22196 * height), control1: CGPoint(x: 0.74052 * width, y: 0.20833 * height), control2: CGPoint(x: 0.77675 * width, y: 0.20834 * height))
        path.addCurve(to: CGPoint(x: 0.8609 * width, y: 0.27657 * height), control1: CGPoint(x: 0.82873 * width, y: 0.23395 * height), control2: CGPoint(x: 0.8485 * width, y: 0.25306 * height))
        path.addCurve(to: CGPoint(x: 0.875 * width, y: 0.40832 * height), control1: CGPoint(x: 0.87499 * width, y: 0.30331 * height), control2: CGPoint(x: 0.875 * width, y: 0.33832 * height))
        path.addLine(to: CGPoint(x: 0.875 * width, y: 0.59168 * height))
        path.addCurve(to: CGPoint(x: 0.8609 * width, y: 0.72343 * height), control1: CGPoint(x: 0.875 * width, y: 0.66168 * height), control2: CGPoint(x: 0.87499 * width, y: 0.69669 * height))
        path.addCurve(to: CGPoint(x: 0.80441 * width, y: 0.77804 * height), control1: CGPoint(x: 0.8485 * width, y: 0.74694 * height), control2: CGPoint(x: 0.82873 * width, y: 0.76605 * height))
        path.addCurve(to: CGPoint(x: 0.6681 * width, y: 0.79167 * height), control1: CGPoint(x: 0.77675 * width, y: 0.79166 * height), control2: CGPoint(x: 0.74052 * width, y: 0.79167 * height))
        path.addLine(to: CGPoint(x: 0.625 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.7613 * width, y: 0.77804 * height), control1: CGPoint(x: 0.69742 * width, y: 0.79167 * height), control2: CGPoint(x: 0.73364 * width, y: 0.79166 * height))
        path.addCurve(to: CGPoint(x: 0.81779 * width, y: 0.72343 * height), control1: CGPoint(x: 0.78563 * width, y: 0.76605 * height), control2: CGPoint(x: 0.8054 * width, y: 0.74694 * height))
        path.addCurve(to: CGPoint(x: 0.8319 * width, y: 0.59168 * height), control1: CGPoint(x: 0.83189 * width, y: 0.69669 * height), control2: CGPoint(x: 0.8319 * width, y: 0.66168 * height))
        path.addLine(to: CGPoint(x: 0.8319 * width, y: 0.40832 * height))
        path.addCurve(to: CGPoint(x: 0.81779 * width, y: 0.27657 * height), control1: CGPoint(x: 0.8319 * width, y: 0.33832 * height), control2: CGPoint(x: 0.83189 * width, y: 0.30331 * height))
        path.addCurve(to: CGPoint(x: 0.7613 * width, y: 0.22196 * height), control1: CGPoint(x: 0.8054 * width, y: 0.25306 * height), control2: CGPoint(x: 0.78563 * width, y: 0.23395 * height))
        path.addCurve(to: CGPoint(x: 0.625 * width, y: 0.20833 * height), control1: CGPoint(x: 0.73364 * width, y: 0.20834 * height), control2: CGPoint(x: 0.69742 * width, y: 0.20833 * height))
        path.addLine(to: CGPoint(x: 0.6681 * width, y: 0.20833 * height))
        path.closeSubpath()
        result.append(
            .fill(path: path, fillColor: colors.secondCard)
        )
        path = Path()

        path.move(to: CGPoint(x: 0.7931 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.92941 * width, y: 0.22196 * height), control1: CGPoint(x: 0.86552 * width, y: 0.20833 * height), control2: CGPoint(x: 0.90175 * width, y: 0.20834 * height))
        path.addCurve(to: CGPoint(x: 0.9859 * width, y: 0.27657 * height), control1: CGPoint(x: 0.95373 * width, y: 0.23395 * height), control2: CGPoint(x: 0.9735 * width, y: 0.25306 * height))
        path.addCurve(to: CGPoint(x: width, y: 0.40832 * height), control1: CGPoint(x: 0.99999 * width, y: 0.30331 * height), control2: CGPoint(x: width, y: 0.33832 * height))
        path.addLine(to: CGPoint(x: width, y: 0.59168 * height))
        path.addCurve(to: CGPoint(x: 0.9859 * width, y: 0.72343 * height), control1: CGPoint(x: width, y: 0.66168 * height), control2: CGPoint(x: 0.99999 * width, y: 0.69669 * height))
        path.addCurve(to: CGPoint(x: 0.92941 * width, y: 0.77804 * height), control1: CGPoint(x: 0.9735 * width, y: 0.74694 * height), control2: CGPoint(x: 0.95373 * width, y: 0.76605 * height))
        path.addCurve(to: CGPoint(x: 0.7931 * width, y: 0.79167 * height), control1: CGPoint(x: 0.90175 * width, y: 0.79166 * height), control2: CGPoint(x: 0.86552 * width, y: 0.79167 * height))
        path.addLine(to: CGPoint(x: 0.75 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.8863 * width, y: 0.77804 * height), control1: CGPoint(x: 0.82242 * width, y: 0.79167 * height), control2: CGPoint(x: 0.85864 * width, y: 0.79166 * height))
        path.addCurve(to: CGPoint(x: 0.94279 * width, y: 0.72343 * height), control1: CGPoint(x: 0.91063 * width, y: 0.76605 * height), control2: CGPoint(x: 0.9304 * width, y: 0.74694 * height))
        path.addCurve(to: CGPoint(x: 0.9569 * width, y: 0.59168 * height), control1: CGPoint(x: 0.95689 * width, y: 0.69669 * height), control2: CGPoint(x: 0.9569 * width, y: 0.66168 * height))
        path.addLine(to: CGPoint(x: 0.9569 * width, y: 0.40832 * height))
        path.addCurve(to: CGPoint(x: 0.94279 * width, y: 0.27657 * height), control1: CGPoint(x: 0.9569 * width, y: 0.33832 * height), control2: CGPoint(x: 0.95689 * width, y: 0.30331 * height))
        path.addCurve(to: CGPoint(x: 0.8863 * width, y: 0.22196 * height), control1: CGPoint(x: 0.9304 * width, y: 0.25306 * height), control2: CGPoint(x: 0.91063 * width, y: 0.23395 * height))
        path.addCurve(to: CGPoint(x: 0.75 * width, y: 0.20833 * height), control1: CGPoint(x: 0.85864 * width, y: 0.20834 * height), control2: CGPoint(x: 0.82242 * width, y: 0.20833 * height))
        path.addLine(to: CGPoint(x: 0.7931 * width, y: 0.20833 * height))
        path.closeSubpath()
        result.append(
            .fill(path: path, fillColor: colors.thirdCard)
        )
        return result
    }
}
