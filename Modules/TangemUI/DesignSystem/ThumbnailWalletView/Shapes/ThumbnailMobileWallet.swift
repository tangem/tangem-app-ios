//
//  ThumbnailMobileWallet.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public enum ThumbnailMobileWalletPathBuilder: ThumbnailPathBuilding {
    public struct FillColors: Equatable {
        public let icon: Color

        public init(icon: Color) {
            self.icon = icon
        }
    }

    /// All Path manipulations below are SVG to SwiftUI conversion
    static func build(
        for size: CGSize,
        with colors: FillColors,
        colorScheme: ColorScheme
    ) -> [ThumbnailPathFillMode] {
        let width = size.width
        let height = size.height
        var path = Path()
        var result: [ThumbnailPathFillMode] = []

        path.move(to: CGPoint(x: 0.25418 * width, y: 0.79167 * height))
        path.addCurve(to: CGPoint(x: 0.16423 * width, y: 0.77065 * height), control1: CGPoint(x: 0.21978 * width, y: 0.79167 * height), control2: CGPoint(x: 0.18980 * width, y: 0.78466 * height))
        path.addCurve(to: CGPoint(x: 0.10460 * width, y: 0.71276 * height), control1: CGPoint(x: 0.13866 * width, y: 0.75664 * height), control2: CGPoint(x: 0.11878 * width, y: 0.73734 * height))
        path.addCurve(to: CGPoint(x: 0.08333 * width, y: 0.62758 * height), control1: CGPoint(x: 0.09042 * width, y: 0.68793 * height), control2: CGPoint(x: 0.08333 * width, y: 0.65954 * height))
        path.addCurve(to: CGPoint(x: 0.09798 * width, y: 0.55568 * height), control1: CGPoint(x: 0.08333 * width, y: 0.60153 * height), control2: CGPoint(x: 0.08821 * width, y: 0.57756 * height))
        path.addCurve(to: CGPoint(x: 0.13947 * width, y: 0.49963 * height), control1: CGPoint(x: 0.10797 * width, y: 0.53380 * height), control2: CGPoint(x: 0.12180 * width, y: 0.51512 * height))
        path.addCurve(to: CGPoint(x: 0.20049 * width, y: 0.46608 * height), control1: CGPoint(x: 0.15714 * width, y: 0.48415 * height), control2: CGPoint(x: 0.17748 * width, y: 0.47296 * height))
        path.addCurve(to: CGPoint(x: 0.22664 * width, y: 0.36468 * height), control1: CGPoint(x: 0.20328 * width, y: 0.42969 * height), control2: CGPoint(x: 0.21199 * width, y: 0.39589 * height))
        path.addCurve(to: CGPoint(x: 0.28452 * width, y: 0.28282 * height), control1: CGPoint(x: 0.24151 * width, y: 0.33346 * height), control2: CGPoint(x: 0.26081 * width, y: 0.30617 * height))
        path.addCurve(to: CGPoint(x: 0.36541 * width, y: 0.22833 * height), control1: CGPoint(x: 0.30823 * width, y: 0.25946 * height), control2: CGPoint(x: 0.33519 * width, y: 0.24127 * height))
        path.addCurve(to: CGPoint(x: 0.46200 * width, y: 0.20833 * height), control1: CGPoint(x: 0.39586 * width, y: 0.21497 * height), control2: CGPoint(x: 0.42806 * width, y: 0.20833 * height))
        path.addCurve(to: CGPoint(x: 0.60112 * width, y: 0.25037 * height), control1: CGPoint(x: 0.51383 * width, y: 0.20833 * height), control2: CGPoint(x: 0.56020 * width, y: 0.22235 * height))
        path.addCurve(to: CGPoint(x: 0.69735 * width, y: 0.36541 * height), control1: CGPoint(x: 0.64226 * width, y: 0.27815 * height), control2: CGPoint(x: 0.67434 * width, y: 0.31666 * height))
        path.addCurve(to: CGPoint(x: 0.78417 * width, y: 0.38090 * height), control1: CGPoint(x: 0.72873 * width, y: 0.36517 * height), control2: CGPoint(x: 0.75767 * width, y: 0.37033 * height))
        path.addCurve(to: CGPoint(x: 0.85390 * width, y: 0.42552 * height), control1: CGPoint(x: 0.81090 * width, y: 0.39147 * height), control2: CGPoint(x: 0.83415 * width, y: 0.40634 * height))
        path.addCurve(to: CGPoint(x: 0.89993 * width, y: 0.49300 * height), control1: CGPoint(x: 0.87366 * width, y: 0.44469 * height), control2: CGPoint(x: 0.88900 * width, y: 0.46718 * height))
        path.addCurve(to: CGPoint(x: 0.91667 * width, y: 0.57743 * height), control1: CGPoint(x: 0.91109 * width, y: 0.51880 * height), control2: CGPoint(x: 0.91667 * width, y: 0.54695 * height))
        path.addCurve(to: CGPoint(x: 0.90063 * width, y: 0.66150 * height), control1: CGPoint(x: 0.91667 * width, y: 0.60743 * height), control2: CGPoint(x: 0.91132 * width, y: 0.63545 * height))
        path.addCurve(to: CGPoint(x: 0.85635 * width, y: 0.72972 * height), control1: CGPoint(x: 0.89017 * width, y: 0.68756 * height), control2: CGPoint(x: 0.87541 * width, y: 0.71030 * height))
        path.addCurve(to: CGPoint(x: 0.79010 * width, y: 0.77508 * height), control1: CGPoint(x: 0.83752 * width, y: 0.74914 * height), control2: CGPoint(x: 0.81543 * width, y: 0.76426 * height))
        path.addCurve(to: CGPoint(x: 0.70851 * width, y: 0.79167 * height), control1: CGPoint(x: 0.76499 * width, y: 0.78614 * height), control2: CGPoint(x: 0.73780 * width, y: 0.79167 * height))
        path.addLine(to: CGPoint(x: 0.25418 * width, y: 0.79167 * height))
        path.closeSubpath()

        result.append(.fill(
            path: path,
            fillColor: colors.icon,
            stroke: colorScheme.defaultStroke
        ))

        return result
    }
}
