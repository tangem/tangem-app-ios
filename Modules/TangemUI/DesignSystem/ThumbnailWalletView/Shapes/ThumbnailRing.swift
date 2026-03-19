//
//  ThumbnailRing.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

typealias ThumbnailRingView = ThumbnailPathBuilderView<ThumbnailRingPathBuilder>

public enum ThumbnailRingPathBuilder: ThumbnailPathBuilding {
    public struct FillColors {
        public let ring: Color

        public init(ring: Color) {
            self.ring = ring
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
        path.move(to: CGPoint(x: 0.43055 * width, y: 0.125 * height))
        path.addCurve(to: CGPoint(x: 0.25 * width, y: 0.5 * height), control1: CGPoint(x: 0.33084 * width, y: 0.125 * height), control2: CGPoint(x: 0.25 * width, y: 0.29289 * height))
        path.addCurve(to: CGPoint(x: 0.43055 * width, y: 0.875 * height), control1: CGPoint(x: 0.25 * width, y: 0.70711 * height), control2: CGPoint(x: 0.33084 * width, y: 0.875 * height))
        path.addLine(to: CGPoint(x: 0.61111 * width, y: 0.875 * height))
        path.addCurve(to: CGPoint(x: 0.79167 * width, y: 0.5 * height), control1: CGPoint(x: 0.71083 * width, y: 0.875 * height), control2: CGPoint(x: 0.79167 * width, y: 0.70711 * height))
        path.addCurve(to: CGPoint(x: 0.61111 * width, y: 0.125 * height), control1: CGPoint(x: 0.79167 * width, y: 0.29289 * height), control2: CGPoint(x: 0.71083 * width, y: 0.125 * height))
        path.addLine(to: CGPoint(x: 0.43055 * width, y: 0.125 * height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.44059 * width, y: 0.1625 * height))
        path.addCurve(to: CGPoint(x: 0.44059 * width, y: 0.8375 * height), control1: CGPoint(x: 0.68345 * width, y: 0.1625 * height), control2: CGPoint(x: 0.68743 * width, y: 0.8375 * height))
        path.addCurve(to: CGPoint(x: 0.44046 * width, y: 0.83519 * height), control1: CGPoint(x: 0.43921 * width, y: 0.8375 * height), control2: CGPoint(x: 0.43912 * width, y: 0.8355 * height))
        path.addCurve(to: CGPoint(x: 0.49512 * width, y: 0.80353 * height), control1: CGPoint(x: 0.45986 * width, y: 0.83071 * height), control2: CGPoint(x: 0.47827 * width, y: 0.81979 * height))
        path.addCurve(to: CGPoint(x: 0.49538 * width, y: 0.79187 * height), control1: CGPoint(x: 0.49836 * width, y: 0.8004 * height), control2: CGPoint(x: 0.49834 * width, y: 0.79528 * height))
        path.addCurve(to: CGPoint(x: 0.41049 * width, y: 0.5 * height), control1: CGPoint(x: 0.44463 * width, y: 0.7334 * height), control2: CGPoint(x: 0.41049 * width, y: 0.6246 * height))
        path.addCurve(to: CGPoint(x: 0.4954 * width, y: 0.20809 * height), control1: CGPoint(x: 0.41049 * width, y: 0.37538 * height), control2: CGPoint(x: 0.44464 * width, y: 0.26655 * height))
        path.addCurve(to: CGPoint(x: 0.49514 * width, y: 0.19643 * height), control1: CGPoint(x: 0.49836 * width, y: 0.20469 * height), control2: CGPoint(x: 0.49838 * width, y: 0.19956 * height))
        path.addCurve(to: CGPoint(x: 0.44046 * width, y: 0.16479 * height), control1: CGPoint(x: 0.47828 * width, y: 0.18018 * height), control2: CGPoint(x: 0.45986 * width, y: 0.16926 * height))
        path.addCurve(to: CGPoint(x: 0.44059 * width, y: 0.1625 * height), control1: CGPoint(x: 0.43912 * width, y: 0.16448 * height), control2: CGPoint(x: 0.43921 * width, y: 0.1625 * height))
        path.closeSubpath()

        return [
            .fill(
                path: path,
                fillColor: colors.ring,
                stroke: colorScheme.stroke(width: width * 0.125)
            ),
        ]
    }
}
