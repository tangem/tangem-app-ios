//
//  ThumbnailRingCard.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

typealias ThumbnailRingCardView = ThumbnailPathBuilderView<ThumbnailRingCardPathBuilder>

public enum ThumbnailRingCardPathBuilder: ThumbnailPathBuilding {
    public struct FillColors: Equatable {
        public let ring: Color
        public let card: Color

        public init(ring: Color, card: Color) {
            self.ring = ring
            self.card = card
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
        let width = size.width
        let height = size.height
        var result: [ThumbnailPathFillMode] = []

        path.move(to: CGPoint(x: 0.19444 * width, y: 0.41667 * height))
        path.addCurve(to: CGPoint(x: 0.08333 * width, y: 0.64583 * height), control1: CGPoint(x: 0.13308 * width, y: 0.41667 * height), control2: CGPoint(x: 0.08333 * width, y: 0.51927 * height))
        path.addCurve(to: CGPoint(x: 0.19444 * width, y: 0.875 * height), control1: CGPoint(x: 0.08333 * width, y: 0.7724 * height), control2: CGPoint(x: 0.13308 * width, y: 0.875 * height))
        path.addLine(to: CGPoint(x: 0.30556 * width, y: 0.875 * height))
        path.addCurve(to: CGPoint(x: 0.41667 * width, y: 0.64583 * height), control1: CGPoint(x: 0.36692 * width, y: 0.875 * height), control2: CGPoint(x: 0.41667 * width, y: 0.7724 * height))
        path.addCurve(to: CGPoint(x: 0.30556 * width, y: 0.41667 * height), control1: CGPoint(x: 0.41667 * width, y: 0.51927 * height), control2: CGPoint(x: 0.36692 * width, y: 0.41667 * height))
        path.addLine(to: CGPoint(x: 0.19444 * width, y: 0.41667 * height))
        path.closeSubpath()

        toSubtract.move(to: CGPoint(x: 0.20062 * width, y: 0.43958 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.20062 * width, y: 0.85208 * height), control1: CGPoint(x: 0.35007 * width, y: 0.43958 * height), control2: CGPoint(x: 0.35252 * width, y: 0.85208 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.20054 * width, y: 0.85067 * height), control1: CGPoint(x: 0.19978 * width, y: 0.85208 * height), control2: CGPoint(x: 0.19972 * width, y: 0.85086 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.23417 * width, y: 0.83133 * height), control1: CGPoint(x: 0.21248 * width, y: 0.84794 * height), control2: CGPoint(x: 0.2238 * width, y: 0.84126 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.23433 * width, y: 0.82419 * height), control1: CGPoint(x: 0.23617 * width, y: 0.82942 * height), control2: CGPoint(x: 0.23615 * width, y: 0.82627 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.1821 * width, y: 0.64583 * height), control1: CGPoint(x: 0.2031 * width, y: 0.78846 * height), control2: CGPoint(x: 0.1821 * width, y: 0.72197 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.23434 * width, y: 0.46745 * height), control1: CGPoint(x: 0.1821 * width, y: 0.56968 * height), control2: CGPoint(x: 0.20311 * width, y: 0.50318 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.23418 * width, y: 0.46031 * height), control1: CGPoint(x: 0.23616 * width, y: 0.46537 * height), control2: CGPoint(x: 0.23618 * width, y: 0.46223 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.20054 * width, y: 0.44098 * height), control1: CGPoint(x: 0.22381 * width, y: 0.45038 * height), control2: CGPoint(x: 0.21248 * width, y: 0.44372 * height))
        toSubtract.addCurve(to: CGPoint(x: 0.20062 * width, y: 0.43958 * height), control1: CGPoint(x: 0.19972 * width, y: 0.4408 * height), control2: CGPoint(x: 0.19978 * width, y: 0.43958 * height))
        toSubtract.closeSubpath()

        result.append(.subtracting(
            origin: path,
            subtracting: toSubtract,
            fillColor: colors.ring,
            stroke: colorScheme.defaultStroke
        ))
        path = Path()

        path.move(to: CGPoint(x: 0.67501 * width, y: 0.20825 * height))
        path.addCurve(to: CGPoint(x: 0.80676 * width, y: 0.22184 * height), control1: CGPoint(x: 0.74501 * width, y: 0.20825 * height), control2: CGPoint(x: 0.78003 * width, y: 0.20822 * height))
        path.addCurve(to: CGPoint(x: 0.86137 * width, y: 0.27649 * height), control1: CGPoint(x: 0.83028 * width, y: 0.23383 * height), control2: CGPoint(x: 0.84939 * width, y: 0.25297 * height))
        path.addCurve(to: CGPoint(x: 0.875 * width, y: 0.40824 * height), control1: CGPoint(x: 0.87499 * width, y: 0.30323 * height), control2: CGPoint(x: 0.875 * width, y: 0.33824 * height))
        path.addLine(to: CGPoint(x: 0.875 * width, y: 0.59155 * height))
        path.addCurve(to: CGPoint(x: 0.86137 * width, y: 0.72331 * height), control1: CGPoint(x: 0.875 * width, y: 0.66156 * height), control2: CGPoint(x: 0.87499 * width, y: 0.69657 * height))
        path.addCurve(to: CGPoint(x: 0.80676 * width, y: 0.77795 * height), control1: CGPoint(x: 0.84939 * width, y: 0.74682 * height), control2: CGPoint(x: 0.83028 * width, y: 0.76597 * height))
        path.addCurve(to: CGPoint(x: 0.67501 * width, y: 0.79158 * height), control1: CGPoint(x: 0.78003 * width, y: 0.79158 * height), control2: CGPoint(x: 0.74501 * width, y: 0.79158 * height))
        path.addLine(to: CGPoint(x: 0.43787 * width, y: 0.79158 * height))
        path.addCurve(to: CGPoint(x: 0.46016 * width, y: 0.64583 * height), control1: CGPoint(x: 0.45213 * width, y: 0.74929 * height), control2: CGPoint(x: 0.46016 * width, y: 0.69908 * height))
        path.addCurve(to: CGPoint(x: 0.42216 * width, y: 0.46171 * height), control1: CGPoint(x: 0.46016 * width, y: 0.57537 * height), control2: CGPoint(x: 0.44612 * width, y: 0.51023 * height))
        path.addCurve(to: CGPoint(x: 0.31201 * width, y: 0.375 * height), control1: CGPoint(x: 0.39915 * width, y: 0.41513 * height), control2: CGPoint(x: 0.36199 * width, y: 0.37501 * height))
        path.addLine(to: CGPoint(x: 0.19165 * width, y: 0.375 * height))
        path.addCurve(to: CGPoint(x: 0.125 * width, y: 0.40218 * height), control1: CGPoint(x: 0.166 * width, y: 0.375 * height), control2: CGPoint(x: 0.14372 * width, y: 0.38559 * height))
        path.addCurve(to: CGPoint(x: 0.13863 * width, y: 0.27649 * height), control1: CGPoint(x: 0.12501 * width, y: 0.33619 * height), control2: CGPoint(x: 0.12541 * width, y: 0.30245 * height))
        path.addCurve(to: CGPoint(x: 0.19324 * width, y: 0.22184 * height), control1: CGPoint(x: 0.15061 * width, y: 0.25297 * height), control2: CGPoint(x: 0.16972 * width, y: 0.23383 * height))
        path.addCurve(to: CGPoint(x: 0.32499 * width, y: 0.20825 * height), control1: CGPoint(x: 0.21998 * width, y: 0.20822 * height), control2: CGPoint(x: 0.25499 * width, y: 0.20825 * height))
        path.addLine(to: CGPoint(x: 0.67501 * width, y: 0.20825 * height))
        path.closeSubpath()

        result.append(
            .fill(
                path: path,
                fillColor: colors.card,
                stroke: colorScheme.defaultStroke
            )
        )
        return result
    }
}
