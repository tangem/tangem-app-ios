//
//  ThumbnailLetterCard.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

typealias ThumbnailLetterCardView = ThumbnailPathBuilderView<ThumbnailLetterCardPathBuilder>

public enum ThumbnailLetterCardPathBuilder: ThumbnailPathBuilding {
    public struct FillColors: Equatable {
        public let card: Color
        public let tLetter: Color

        public init(card: Color, tLetter: Color) {
            self.card = card
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
        let width = size.width
        let height = size.height
        var result: [ThumbnailPathFillMode] = []

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
        path.move(to: CGPoint(x: 0.32499 * width, y: 0.22917 * height))
        path.addLine(to: CGPoint(x: 0.67501 * width, y: 0.22917 * height))
        path.addCurve(to: CGPoint(x: 0.75541 * width, y: 0.23079 * height), control1: CGPoint(x: 0.71035 * width, y: 0.22917 * height), control2: CGPoint(x: 0.73561 * width, y: 0.22918 * height))
        path.addCurve(to: CGPoint(x: 0.79728 * width, y: 0.24052 * height), control1: CGPoint(x: 0.77496 * width, y: 0.23239 * height), control2: CGPoint(x: 0.78734 * width, y: 0.23546 * height))
        path.addCurve(to: CGPoint(x: 0.84281 * width, y: 0.28605 * height), control1: CGPoint(x: 0.81688 * width, y: 0.25051 * height), control2: CGPoint(x: 0.83283 * width, y: 0.26645 * height))
        path.addCurve(to: CGPoint(x: 0.85254 * width, y: 0.32792 * height), control1: CGPoint(x: 0.84788 * width, y: 0.29599 * height), control2: CGPoint(x: 0.85094 * width, y: 0.30838 * height))
        path.addCurve(to: CGPoint(x: 0.85417 * width, y: 0.40832 * height), control1: CGPoint(x: 0.85416 * width, y: 0.34772 * height), control2: CGPoint(x: 0.85417 * width, y: 0.37298 * height))
        path.addLine(to: CGPoint(x: 0.85417 * width, y: 0.59168 * height))
        path.addCurve(to: CGPoint(x: 0.85254 * width, y: 0.67208 * height), control1: CGPoint(x: 0.85417 * width, y: 0.62702 * height), control2: CGPoint(x: 0.85416 * width, y: 0.65228 * height))
        path.addCurve(to: CGPoint(x: 0.84281 * width, y: 0.71395 * height), control1: CGPoint(x: 0.85094 * width, y: 0.69163 * height), control2: CGPoint(x: 0.84788 * width, y: 0.70401 * height))
        path.addCurve(to: CGPoint(x: 0.79728 * width, y: 0.75948 * height), control1: CGPoint(x: 0.83283 * width, y: 0.73355 * height), control2: CGPoint(x: 0.81688 * width, y: 0.7495 * height))
        path.addCurve(to: CGPoint(x: 0.75541 * width, y: 0.7692 * height), control1: CGPoint(x: 0.78734 * width, y: 0.76455 * height), control2: CGPoint(x: 0.77496 * width, y: 0.76761 * height))
        path.addCurve(to: CGPoint(x: 0.67501 * width, y: 0.77083 * height), control1: CGPoint(x: 0.73561 * width, y: 0.77082 * height), control2: CGPoint(x: 0.71035 * width, y: 0.77083 * height))
        path.addLine(to: CGPoint(x: 0.32499 * width, y: 0.77083 * height))
        path.addCurve(to: CGPoint(x: 0.24459 * width, y: 0.7692 * height), control1: CGPoint(x: 0.28965 * width, y: 0.77083 * height), control2: CGPoint(x: 0.26439 * width, y: 0.77082 * height))
        path.addCurve(to: CGPoint(x: 0.20272 * width, y: 0.75948 * height), control1: CGPoint(x: 0.22504 * width, y: 0.76761 * height), control2: CGPoint(x: 0.21266 * width, y: 0.76455 * height))
        path.addCurve(to: CGPoint(x: 0.15719 * width, y: 0.71395 * height), control1: CGPoint(x: 0.18312 * width, y: 0.7495 * height), control2: CGPoint(x: 0.16717 * width, y: 0.73355 * height))
        path.addCurve(to: CGPoint(x: 0.14746 * width, y: 0.67208 * height), control1: CGPoint(x: 0.15212 * width, y: 0.70401 * height), control2: CGPoint(x: 0.14906 * width, y: 0.69163 * height))
        path.addCurve(to: CGPoint(x: 0.14583 * width, y: 0.59168 * height), control1: CGPoint(x: 0.14584 * width, y: 0.65228 * height), control2: CGPoint(x: 0.14583 * width, y: 0.62702 * height))
        path.addLine(to: CGPoint(x: 0.14583 * width, y: 0.40832 * height))
        path.addCurve(to: CGPoint(x: 0.14746 * width, y: 0.32792 * height), control1: CGPoint(x: 0.14583 * width, y: 0.37298 * height), control2: CGPoint(x: 0.14584 * width, y: 0.34772 * height))
        path.addCurve(to: CGPoint(x: 0.15719 * width, y: 0.28605 * height), control1: CGPoint(x: 0.14906 * width, y: 0.30838 * height), control2: CGPoint(x: 0.15212 * width, y: 0.29599 * height))
        path.addCurve(to: CGPoint(x: 0.20272 * width, y: 0.24052 * height), control1: CGPoint(x: 0.16717 * width, y: 0.26645 * height), control2: CGPoint(x: 0.18312 * width, y: 0.25051 * height))
        path.addCurve(to: CGPoint(x: 0.24459 * width, y: 0.23079 * height), control1: CGPoint(x: 0.21266 * width, y: 0.23546 * height), control2: CGPoint(x: 0.22504 * width, y: 0.23239 * height))
        path.addCurve(to: CGPoint(x: 0.32499 * width, y: 0.22917 * height), control1: CGPoint(x: 0.26439 * width, y: 0.22918 * height), control2: CGPoint(x: 0.28965 * width, y: 0.22917 * height))
        path.closeSubpath()

        result.append(
            .fill(
                path: path,
                fillColor: colors.card,
                stroke: colorScheme.defaultStroke
            )
        )
        path = Path()

        path.move(to: CGPoint(x: 0.46174 * width, y: 0.66667 * height))
        path.addLine(to: CGPoint(x: 0.46174 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.375 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.375 * width, y: 0.33333 * height))
        path.addLine(to: CGPoint(x: 0.625 * width, y: 0.33333 * height))
        path.addLine(to: CGPoint(x: 0.625 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.53805 * width, y: 0.40148 * height))
        path.addLine(to: CGPoint(x: 0.53805 * width, y: 0.66667 * height))
        path.addLine(to: CGPoint(x: 0.46174 * width, y: 0.66667 * height))
        path.closeSubpath()

        result.append(.fill(path: path, fillColor: colors.tLetter))

        return result
    }
}
