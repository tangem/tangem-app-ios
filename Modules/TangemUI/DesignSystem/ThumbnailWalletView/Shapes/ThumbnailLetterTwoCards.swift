//
//  ThumbnailLetterTwoCards.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

typealias ThumbnailLetterTwoCardsView = ThumbnailPathBuilderView<ThumbnailLetterTwoCardsPathBuilder>

public enum ThumbnailLetterTwoCardsPathBuilder: ThumbnailPathBuilding {
    public struct FillColors {
        public let card: Color
        public let secondCard: Color
        public let tLetter: Color

        public init(card: Color, secondCard: Color, tLetter: Color) {
            self.card = card
            self.secondCard = secondCard
            self.tLetter = tLetter
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
        path.move(to: CGPoint(x: 0.28332 * width, y: 0.22917 * height))
        path.addLine(to: CGPoint(x: 0.63334 * width, y: 0.22917 * height))
        path.addCurve(to: CGPoint(x: 0.71375 * width, y: 0.23079 * height), control1: CGPoint(x: 0.66868 * width, y: 0.22917 * height), control2: CGPoint(x: 0.69395 * width, y: 0.22918 * height))
        path.addCurve(to: CGPoint(x: 0.75562 * width, y: 0.24052 * height), control1: CGPoint(x: 0.73329 * width, y: 0.23239 * height), control2: CGPoint(x: 0.74567 * width, y: 0.23546 * height))
        path.addCurve(to: CGPoint(x: 0.80115 * width, y: 0.28605 * height), control1: CGPoint(x: 0.77522 * width, y: 0.25051 * height), control2: CGPoint(x: 0.79116 * width, y: 0.26645 * height))
        path.addCurve(to: CGPoint(x: 0.81087 * width, y: 0.32792 * height), control1: CGPoint(x: 0.80621 * width, y: 0.29599 * height), control2: CGPoint(x: 0.80927 * width, y: 0.30838 * height))
        path.addCurve(to: CGPoint(x: 0.8125 * width, y: 0.40832 * height), control1: CGPoint(x: 0.81249 * width, y: 0.34772 * height), control2: CGPoint(x: 0.8125 * width, y: 0.37298 * height))
        path.addLine(to: CGPoint(x: 0.8125 * width, y: 0.59168 * height))
        path.addCurve(to: CGPoint(x: 0.81087 * width, y: 0.67208 * height), control1: CGPoint(x: 0.8125 * width, y: 0.62702 * height), control2: CGPoint(x: 0.81249 * width, y: 0.65228 * height))
        path.addCurve(to: CGPoint(x: 0.80115 * width, y: 0.71395 * height), control1: CGPoint(x: 0.80927 * width, y: 0.69163 * height), control2: CGPoint(x: 0.80621 * width, y: 0.70401 * height))
        path.addCurve(to: CGPoint(x: 0.75562 * width, y: 0.75948 * height), control1: CGPoint(x: 0.79116 * width, y: 0.73355 * height), control2: CGPoint(x: 0.77522 * width, y: 0.7495 * height))
        path.addCurve(to: CGPoint(x: 0.71375 * width, y: 0.7692 * height), control1: CGPoint(x: 0.74567 * width, y: 0.76455 * height), control2: CGPoint(x: 0.73329 * width, y: 0.76761 * height))
        path.addCurve(to: CGPoint(x: 0.63334 * width, y: 0.77083 * height), control1: CGPoint(x: 0.69395 * width, y: 0.77082 * height), control2: CGPoint(x: 0.66868 * width, y: 0.77083 * height))
        path.addLine(to: CGPoint(x: 0.28332 * width, y: 0.77083 * height))
        path.addCurve(to: CGPoint(x: 0.20292 * width, y: 0.7692 * height), control1: CGPoint(x: 0.24798 * width, y: 0.77083 * height), control2: CGPoint(x: 0.22272 * width, y: 0.77082 * height))
        path.addCurve(to: CGPoint(x: 0.16105 * width, y: 0.75948 * height), control1: CGPoint(x: 0.18338 * width, y: 0.76761 * height), control2: CGPoint(x: 0.17099 * width, y: 0.76455 * height))
        path.addCurve(to: CGPoint(x: 0.11552 * width, y: 0.71395 * height), control1: CGPoint(x: 0.14145 * width, y: 0.7495 * height), control2: CGPoint(x: 0.12551 * width, y: 0.73355 * height))
        path.addCurve(to: CGPoint(x: 0.10579 * width, y: 0.67208 * height), control1: CGPoint(x: 0.11046 * width, y: 0.70401 * height), control2: CGPoint(x: 0.10739 * width, y: 0.69163 * height))
        path.addCurve(to: CGPoint(x: 0.10417 * width, y: 0.59168 * height), control1: CGPoint(x: 0.10418 * width, y: 0.65228 * height), control2: CGPoint(x: 0.10417 * width, y: 0.62702 * height))
        path.addLine(to: CGPoint(x: 0.10417 * width, y: 0.40832 * height))
        path.addCurve(to: CGPoint(x: 0.10579 * width, y: 0.32792 * height), control1: CGPoint(x: 0.10417 * width, y: 0.37298 * height), control2: CGPoint(x: 0.10418 * width, y: 0.34772 * height))
        path.addCurve(to: CGPoint(x: 0.11552 * width, y: 0.28605 * height), control1: CGPoint(x: 0.10739 * width, y: 0.30838 * height), control2: CGPoint(x: 0.11046 * width, y: 0.29599 * height))
        path.addCurve(to: CGPoint(x: 0.16105 * width, y: 0.24052 * height), control1: CGPoint(x: 0.12551 * width, y: 0.26645 * height), control2: CGPoint(x: 0.14145 * width, y: 0.25051 * height))
        path.addCurve(to: CGPoint(x: 0.20292 * width, y: 0.23079 * height), control1: CGPoint(x: 0.17099 * width, y: 0.23546 * height), control2: CGPoint(x: 0.18338 * width, y: 0.23239 * height))
        path.addCurve(to: CGPoint(x: 0.28332 * width, y: 0.22917 * height), control1: CGPoint(x: 0.22272 * width, y: 0.22918 * height), control2: CGPoint(x: 0.24798 * width, y: 0.22917 * height))
        path.closeSubpath()
        result.append(
            .fill(
                path: path,
                fillColor: colors.card,
                stroke: colorScheme.stroke(width: width * 0.03)
            )
        )
        path = Path()

        path.move(to: CGPoint(x: 0.42007 * width, y: 0.66667 * height))
        path.addLine(to: CGPoint(x: 0.42007 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.33333 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.33333 * width, y: 0.33333 * height))
        path.addLine(to: CGPoint(x: 0.58333 * width, y: 0.33333 * height))
        path.addLine(to: CGPoint(x: 0.58333 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.49639 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.49639 * width, y: 0.66667 * height))
        path.addLine(to: CGPoint(x: 0.42007 * width, y: 0.66667 * height))
        path.closeSubpath()
        result.append(.fill(path: path, fillColor: colors.tLetter))
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
        path.move(to: CGPoint(x: 0.90963 * width, y: 0.29806 * height))
        path.addCurve(to: CGPoint(x: 0.91496 * width, y: 0.32796 * height), control1: CGPoint(x: 0.91208 * width, y: 0.30591 * height), control2: CGPoint(x: 0.9139 * width, y: 0.31543 * height))
        path.addCurve(to: CGPoint(x: 0.91667 * width, y: 0.40832 * height), control1: CGPoint(x: 0.91663 * width, y: 0.34773 * height), control2: CGPoint(x: 0.91667 * width, y: 0.37297 * height))
        path.addLine(to: CGPoint(x: 0.91667 * width, y: 0.59168 * height))
        path.addCurve(to: CGPoint(x: 0.91496 * width, y: 0.67204 * height), control1: CGPoint(x: 0.91667 * width, y: 0.62703 * height), control2: CGPoint(x: 0.91663 * width, y: 0.65228 * height))
        path.addCurve(to: CGPoint(x: 0.90963 * width, y: 0.7019 * height), control1: CGPoint(x: 0.9139 * width, y: 0.68455 * height), control2: CGPoint(x: 0.91207 * width, y: 0.69405 * height))
        path.addCurve(to: CGPoint(x: 0.91337 * width, y: 0.67554 * height), control1: CGPoint(x: 0.91137 * width, y: 0.69366 * height), control2: CGPoint(x: 0.91258 * width, y: 0.68493 * height))
        path.addCurve(to: CGPoint(x: 0.91524 * width, y: 0.59168 * height), control1: CGPoint(x: 0.91522 * width, y: 0.65361 * height), control2: CGPoint(x: 0.91524 * width, y: 0.62632 * height))
        path.addLine(to: CGPoint(x: 0.91524 * width, y: 0.40832 * height))
        path.addCurve(to: CGPoint(x: 0.91337 * width, y: 0.32446 * height), control1: CGPoint(x: 0.91524 * width, y: 0.37368 * height), control2: CGPoint(x: 0.91522 * width, y: 0.34639 * height))
        path.addCurve(to: CGPoint(x: 0.90963 * width, y: 0.29806 * height), control1: CGPoint(x: 0.91258 * width, y: 0.31505 * height), control2: CGPoint(x: 0.91138 * width, y: 0.30631 * height))
        path.closeSubpath()
        result.append(.fill(path: path, fillColor: colors.secondCard))

        return result
    }
}
