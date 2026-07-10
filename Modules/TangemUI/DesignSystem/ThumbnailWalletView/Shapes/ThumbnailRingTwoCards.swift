//
//  ThumbnailRingTwoCards.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

typealias ThumbnailRingTwoCardsView = ThumbnailPathBuilderView<ThumbnailRingTwoCardsPathBuilder>

public enum ThumbnailRingTwoCardsPathBuilder: ThumbnailPathBuilding {
    public struct FillColors: Equatable {
        public let ring: Color
        public let card: Color
        public let secondCard: Color

        public init(ring: Color, card: Color, secondCard: Color) {
            self.ring = ring
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
        var toSubtract = Path()
        var result: [ThumbnailPathFillMode] = []
        let width = size.width
        let height = size.height

        path.move(to: CGPoint(x: 0.1529166667 * width, y: 0.4166666667 * height))
        path.addCurve(to: CGPoint(x: 0.0416666667 * width, y: 0.6458333333 * height), control1: CGPoint(x: 0.09125 * width, y: 0.4166666667 * height), control2: CGPoint(x: 0.0416666667 * width, y: 0.5191666667 * height))
        path.addCurve(to: CGPoint(x: 0.1529166667 * width, y: 0.875 * height), control1: CGPoint(x: 0.0416666667 * width, y: 0.7725 * height), control2: CGPoint(x: 0.09125 * width, y: 0.875 * height))
        path.addLine(to: CGPoint(x: 0.26375 * width, y: 0.875 * height))
        path.addCurve(to: CGPoint(x: 0.375 * width, y: 0.6458333333 * height), control1: CGPoint(x: 0.3254166667 * width, y: 0.875 * height), control2: CGPoint(x: 0.375 * width, y: 0.7725 * height))
        path.addCurve(to: CGPoint(x: 0.26375 * width, y: 0.4166666667 * height), control1: CGPoint(x: 0.375 * width, y: 0.5191666667 * height), control2: CGPoint(x: 0.3254166667 * width, y: 0.4166666667 * height))
        path.addLine(to: CGPoint(x: 0.1529166667 * width, y: 0.4166666667 * height))
        path.closeSubpath()

        toSubtract.move(to: CGPoint(x: 0.15875 * width, y: 0.4395833333 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.15875 * width, y: 0.8520833333 * height), control1: CGPoint(x: 0.3083333333 * width, y: 0.4395833333 * height), control2: CGPoint(x: 0.3108333333 * width, y: 0.8520833333 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.15875 * width, y: 0.8508333333 * height), control1: CGPoint(x: 0.1579166667 * width, y: 0.8520833333 * height), control2: CGPoint(x: 0.1579166667 * width, y: 0.8508333333 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.1925 * width, y: 0.83125 * height), control1: CGPoint(x: 0.1708333333 * width, y: 0.8479166667 * height), control2: CGPoint(x: 0.1820833333 * width, y: 0.84125 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.1925 * width, y: 0.8241666667 * height), control1: CGPoint(x: 0.1945833333 * width, y: 0.8295833333 * height), control2: CGPoint(x: 0.1945833333 * width, y: 0.82625 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.1404166667 * width, y: 0.6458333333 * height), control1: CGPoint(x: 0.16125 * width, y: 0.7883333333 * height), control2: CGPoint(x: 0.1404166667 * width, y: 0.7220833333 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.1925 * width, y: 0.4675 * height), control1: CGPoint(x: 0.1404166667 * width, y: 0.5695833333 * height), control2: CGPoint(x: 0.16125 * width, y: 0.5033333333 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.1925 * width, y: 0.4604166667 * height), control1: CGPoint(x: 0.1945833333 * width, y: 0.4654166667 * height), control2: CGPoint(x: 0.1945833333 * width, y: 0.4620833333 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.15875 * width, y: 0.4408333333 * height), control1: CGPoint(x: 0.1820833333 * width, y: 0.4504166667 * height), control2: CGPoint(x: 0.1708333333 * width, y: 0.44375 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.15875 * width, y: 0.4395833333 * height), control1: CGPoint(x: 0.1579166667 * width, y: 0.4408333333 * height), control2: CGPoint(x: 0.1579166667 * width, y: 0.4395833333 * height))

        result.append(
            .subtracting(
                origin: path,
                subtracting: toSubtract,
                fillColor: colors.ring,
                stroke: colorScheme.defaultStroke
            )
        )
        path = Path()

        path.move(to: CGPoint(x: 0.6333333333 * width, y: 0.2083333333 * height))
        path.addCurve(to: CGPoint(x: 0.765 * width, y: 0.2216666667 * height), control1: CGPoint(x: 0.7033333333 * width, y: 0.2083333333 * height), control2: CGPoint(x: 0.7383333333 * width, y: 0.2083333333 * height))
        path.addCurve(to: CGPoint(x: 0.8195833333 * width, y: 0.2766666667 * height), control1: CGPoint(x: 0.78875 * width, y: 0.23375 * height), control2: CGPoint(x: 0.8079166667 * width, y: 0.2529166667 * height))
        path.addCurve(to: CGPoint(x: 0.8333333333 * width, y: 0.4083333333 * height), control1: CGPoint(x: 0.8333333333 * width, y: 0.3033333333 * height), control2: CGPoint(x: 0.8333333333 * width, y: 0.3383333333 * height))
        path.addLine(to: CGPoint(x: 0.8333333333 * width, y: 0.5916666667 * height))
        path.addCurve(to: CGPoint(x: 0.8195833333 * width, y: 0.7233333333 * height), control1: CGPoint(x: 0.8333333333 * width, y: 0.6616666667 * height), control2: CGPoint(x: 0.8333333333 * width, y: 0.6966666667 * height))
        path.addCurve(to: CGPoint(x: 0.765 * width, y: 0.7779166667 * height), control1: CGPoint(x: 0.8079166667 * width, y: 0.7466666667 * height), control2: CGPoint(x: 0.78875 * width, y: 0.7658333333 * height))
        path.addCurve(to: CGPoint(x: 0.6333333333 * width, y: 0.7916666667 * height), control1: CGPoint(x: 0.7383333333 * width, y: 0.7916666667 * height), control2: CGPoint(x: 0.7033333333 * width, y: 0.7916666667 * height))
        path.addLine(to: CGPoint(x: 0.39625 * width, y: 0.7916666667 * height))
        path.addCurve(to: CGPoint(x: 0.4183333333 * width, y: 0.6458333333 * height), control1: CGPoint(x: 0.4104166667 * width, y: 0.7491666667 * height), control2: CGPoint(x: 0.4183333333 * width, y: 0.6991666667 * height))
        path.addCurve(to: CGPoint(x: 0.3804166667 * width, y: 0.4616666667 * height), control1: CGPoint(x: 0.4183333333 * width, y: 0.5754166667 * height), control2: CGPoint(x: 0.4045833333 * width, y: 0.5104166667 * height))
        path.addCurve(to: CGPoint(x: 0.2704166667 * width, y: 0.375 * height), control1: CGPoint(x: 0.3575 * width, y: 0.415 * height), control2: CGPoint(x: 0.3204166667 * width, y: 0.375 * height))
        path.addLine(to: CGPoint(x: 0.15 * width, y: 0.375 * height))
        path.addCurve(to: CGPoint(x: 0.0833333333 * width, y: 0.4020833333 * height), control1: CGPoint(x: 0.1241666667 * width, y: 0.375 * height), control2: CGPoint(x: 0.1020833333 * width, y: 0.3854166667 * height))
        path.addCurve(to: CGPoint(x: 0.0970833333 * width, y: 0.2766666667 * height), control1: CGPoint(x: 0.0833333333 * width, y: 0.33625 * height), control2: CGPoint(x: 0.08375 * width, y: 0.3025 * height))
        path.addCurve(to: CGPoint(x: 0.1516666667 * width, y: 0.2216666667 * height), control1: CGPoint(x: 0.10875 * width, y: 0.2529166667 * height), control2: CGPoint(x: 0.1279166667 * width, y: 0.23375 * height))
        path.addCurve(to: CGPoint(x: 0.2833333333 * width, y: 0.2083333333 * height), control1: CGPoint(x: 0.1783333333 * width, y: 0.2083333333 * height), control2: CGPoint(x: 0.2133333333 * width, y: 0.2083333333 * height))
        path.addLine(to: CGPoint(x: 0.6333333333 * width, y: 0.2083333333 * height))
        path.closeSubpath()

        result.append(
            .fill(
                path: path,
                fillColor: colors.card,
                stroke: colorScheme.defaultStroke
            )
        )
        path = .init()

        path.move(to: CGPoint(x: 0.75125 * width, y: 0.2083333333 * height))
        path.addCurve(to: CGPoint(x: 0.8879166667 * width, y: 0.2220833333 * height), control1: CGPoint(x: 0.82375 * width, y: 0.2083333333 * height), control2: CGPoint(x: 0.86 * width, y: 0.2083333333 * height))
        path.addCurve(to: CGPoint(x: 0.9441666667 * width, y: 0.2766666667 * height), control1: CGPoint(x: 0.9120833333 * width, y: 0.23375 * height), control2: CGPoint(x: 0.9316666667 * width, y: 0.2529166667 * height))
        path.addCurve(to: CGPoint(x: 0.9583333333 * width, y: 0.4083333333 * height), control1: CGPoint(x: 0.9583333333 * width, y: 0.3033333333 * height), control2: CGPoint(x: 0.9583333333 * width, y: 0.3383333333 * height))
        path.addLine(to: CGPoint(x: 0.9583333333 * width, y: 0.5916666667 * height))
        path.addCurve(to: CGPoint(x: 0.9441666667 * width, y: 0.7233333333 * height), control1: CGPoint(x: 0.9583333333 * width, y: 0.6616666667 * height), control2: CGPoint(x: 0.9583333333 * width, y: 0.6966666667 * height))
        path.addCurve(to: CGPoint(x: 0.8879166667 * width, y: 0.7779166667 * height), control1: CGPoint(x: 0.9316666667 * width, y: 0.7470833333 * height), control2: CGPoint(x: 0.9120833333 * width, y: 0.76625 * height))
        path.addCurve(to: CGPoint(x: 0.75125 * width, y: 0.7916666667 * height), control1: CGPoint(x: 0.86 * width, y: 0.7916666667 * height), control2: CGPoint(x: 0.82375 * width, y: 0.7916666667 * height))
        path.addLine(to: CGPoint(x: 0.7083333333 * width, y: 0.7916666667 * height))
        path.addCurve(to: CGPoint(x: 0.8445833333 * width, y: 0.7779166667 * height), control1: CGPoint(x: 0.7808333333 * width, y: 0.7916666667 * height), control2: CGPoint(x: 0.8170833333 * width, y: 0.7916666667 * height))
        path.addCurve(to: CGPoint(x: 0.90125 * width, y: 0.7233333333 * height), control1: CGPoint(x: 0.8691666667 * width, y: 0.76625 * height), control2: CGPoint(x: 0.88875 * width, y: 0.7470833333 * height))
        path.addCurve(to: CGPoint(x: 0.9154166667 * width, y: 0.5916666667 * height), control1: CGPoint(x: 0.9154166667 * width, y: 0.6966666667 * height), control2: CGPoint(x: 0.9154166667 * width, y: 0.6616666667 * height))
        path.addLine(to: CGPoint(x: 0.9154166667 * width, y: 0.4083333333 * height))
        path.addCurve(to: CGPoint(x: 0.90125 * width, y: 0.2766666667 * height), control1: CGPoint(x: 0.9154166667 * width, y: 0.3383333333 * height), control2: CGPoint(x: 0.9154166667 * width, y: 0.3033333333 * height))
        path.addCurve(to: CGPoint(x: 0.8445833333 * width, y: 0.2220833333 * height), control1: CGPoint(x: 0.88875 * width, y: 0.2529166667 * height), control2: CGPoint(x: 0.8691666667 * width, y: 0.23375 * height))
        path.addCurve(to: CGPoint(x: 0.7083333333 * width, y: 0.2083333333 * height), control1: CGPoint(x: 0.8170833333 * width, y: 0.2083333333 * height), control2: CGPoint(x: 0.7808333333 * width, y: 0.2083333333 * height))
        path.addLine(to: CGPoint(x: 0.75125 * width, y: 0.2083333333 * height))
        path.closeSubpath()

        result.append(.fill(path: path, fillColor: colors.secondCard))

        return result
    }
}
