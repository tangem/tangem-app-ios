//
//  ThumbnailCard.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

typealias ThumbnailCardView = ThumbnailPathBuilderView<ThumbnailCardPathBuilder>

public enum ThumbnailCardPathBuilder: ThumbnailPathBuilding {
    public struct FillColors {
        public let card: Color

        public init(card: Color) {
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
        var result: [ThumbnailPathFillMode] = []
        let width = size.width
        let height = size.height
        path.move(to: CGPoint(x: 0.125 * width, y: 0.40833 * height))
        path.addCurve(to: CGPoint(x: 0.13862 * width, y: 0.27658 * height), control1: CGPoint(x: 0.125 * width, y: 0.33833 * height), control2: CGPoint(x: 0.125 * width, y: 0.30332 * height))
        path.addCurve(to: CGPoint(x: 0.19325 * width, y: 0.22196 * height), control1: CGPoint(x: 0.15061 * width, y: 0.25306 * height), control2: CGPoint(x: 0.16973 * width, y: 0.23394 * height))
        path.addCurve(to: CGPoint(x: 0.325 * width, y: 0.20833 * height), control1: CGPoint(x: 0.21999 * width, y: 0.20833 * height), control2: CGPoint(x: 0.25499 * width, y: 0.20833 * height))
        path.addLine(to: CGPoint(x: 0.675 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.80675 * width, y: 0.22196 * height), control1: CGPoint(x: 0.74501 * width, y: 0.20833 * height), control2: CGPoint(x: 0.78001 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.86137 * width, y: 0.27658 * height), control1: CGPoint(x: 0.83027 * width, y: 0.23394 * height), control2: CGPoint(x: 0.84939 * width, y: 0.25306 * height))
        path.addCurve(to: CGPoint(x: 0.875 * width, y: 0.40833 * height), control1: CGPoint(x: 0.875 * width, y: 0.30332 * height), control2: CGPoint(x: 0.875 * width, y: 0.33833 * height))
        path.addLine(to: CGPoint(x: 0.875 * width, y: 0.59167 * height))
        path.addCurve(to: CGPoint(x: 0.86137 * width, y: 0.72342 * height), control1: CGPoint(x: 0.875 * width, y: 0.66168 * height), control2: CGPoint(x: 0.875 * width, y: 0.69667 * height))
        path.addCurve(to: CGPoint(x: 0.80675 * width, y: 0.77804 * height), control1: CGPoint(x: 0.84939 * width, y: 0.74694 * height), control2: CGPoint(x: 0.83027 * width, y: 0.76606 * height))
        path.addCurve(to: CGPoint(x: 0.675 * width, y: 0.79167 * height), control1: CGPoint(x: 0.78001 * width, y: 0.79167 * height), control2: CGPoint(x: 0.74501 * width, y: 0.79167 * height))
        path.addLine(to: CGPoint(x: 0.325 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.19325 * width, y: 0.77804 * height), control1: CGPoint(x: 0.25499 * width, y: 0.79167 * height), control2: CGPoint(x: 0.21999 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.13862 * width, y: 0.72342 * height), control1: CGPoint(x: 0.16973 * width, y: 0.76606 * height), control2: CGPoint(x: 0.15061 * width, y: 0.74694 * height))
        path.addCurve(to: CGPoint(x: 0.125 * width, y: 0.59167 * height), control1: CGPoint(x: 0.125 * width, y: 0.69667 * height), control2: CGPoint(x: 0.125 * width, y: 0.66168 * height))
        path.addLine(to: CGPoint(x: 0.125 * width, y: 0.40833 * height))
        path.closeSubpath()

        result.append(
            .fill(
                path: path,
                fillColor: colors.card,
                stroke: colorScheme.stroke(width: width * 0.03)
            )
        )

        return result
    }
}
