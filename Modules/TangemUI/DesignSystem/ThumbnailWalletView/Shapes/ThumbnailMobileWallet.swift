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
        var path = Path()
        let width = size.width
        let height = size.height
        var result: [ThumbnailPathFillMode] = []

        path.move(to: CGPoint(x: 0.5 * width, y: 0.08333 * height))
        path.addCurve(to: CGPoint(x: 0.51713 * width, y: 0.08492 * height), control1: CGPoint(x: 0.50571 * width, y: 0.08333 * height), control2: CGPoint(x: 0.51143 * width, y: 0.08386 * height))
        path.addCurve(to: CGPoint(x: 0.53381 * width, y: 0.08891 * height), control1: CGPoint(x: 0.52283 * width, y: 0.08598 * height), control2: CGPoint(x: 0.52839 * width, y: 0.08732 * height))
        path.addCurve(to: CGPoint(x: 0.57255 * width, y: 0.10246 * height), control1: CGPoint(x: 0.54332 * width, y: 0.09209 * height), control2: CGPoint(x: 0.55625 * width, y: 0.09662 * height))
        path.addCurve(to: CGPoint(x: 0.62716 * width, y: 0.12158 * height), control1: CGPoint(x: 0.58912 * width, y: 0.10803 * height), control2: CGPoint(x: 0.60733 * width, y: 0.11442 * height))
        path.addCurve(to: CGPoint(x: 0.68705 * width, y: 0.14307 * height), control1: CGPoint(x: 0.64725 * width, y: 0.12875 * height), control2: CGPoint(x: 0.66723 * width, y: 0.13590 * height))
        path.addCurve(to: CGPoint(x: 0.74207 * width, y: 0.16297 * height), control1: CGPoint(x: 0.70715 * width, y: 0.15023 * height), control2: CGPoint(x: 0.72550 * width, y: 0.15686 * height))
        path.addCurve(to: CGPoint(x: 0.78117 * width, y: 0.17810 * height), control1: CGPoint(x: 0.75863 * width, y: 0.16907 * height), control2: CGPoint(x: 0.77167 * width, y: 0.17412 * height))
        path.addCurve(to: CGPoint(x: 0.81990 * width, y: 0.20198 * height), control1: CGPoint(x: 0.79828 * width, y: 0.18500 * height), control2: CGPoint(x: 0.81121 * width, y: 0.19296 * height))
        path.addCurve(to: CGPoint(x: 0.83333 * width, y: 0.24622 * height), control1: CGPoint(x: 0.82887 * width, y: 0.21101 * height), control2: CGPoint(x: 0.83333 * width, y: 0.22577 * height))
        path.addLine(to: CGPoint(x: 0.83333 * width, y: 0.54647 * height))
        path.addCurve(to: CGPoint(x: 0.81783 * width, y: 0.64083 * height), control1: CGPoint(x: 0.83333 * width, y: 0.58230 * height), control2: CGPoint(x: 0.82815 * width, y: 0.61375 * height))
        path.addCurve(to: CGPoint(x: 0.76693 * width, y: 0.71610 * height), control1: CGPoint(x: 0.80751 * width, y: 0.66764 * height), control2: CGPoint(x: 0.79056 * width, y: 0.69275 * height))
        path.addCurve(to: CGPoint(x: 0.67277 * width, y: 0.78699 * height), control1: CGPoint(x: 0.74356 * width, y: 0.73947 * height), control2: CGPoint(x: 0.71216 * width, y: 0.76310 * height))
        path.addCurve(to: CGPoint(x: 0.52690 * width, y: 0.86743 * height), control1: CGPoint(x: 0.63365 * width, y: 0.81088 * height), control2: CGPoint(x: 0.58503 * width, y: 0.83770 * height))
        path.addCurve(to: CGPoint(x: 0.51180 * width, y: 0.87300 * height), control1: CGPoint(x: 0.52173 * width, y: 0.87009 * height), control2: CGPoint(x: 0.51669 * width, y: 0.87195 * height))
        path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.87500 * height), control1: CGPoint(x: 0.50719 * width, y: 0.87433 * height), control2: CGPoint(x: 0.50326 * width, y: 0.87500 * height))
        path.addCurve(to: CGPoint(x: 0.48779 * width, y: 0.87300 * height), control1: CGPoint(x: 0.49674 * width, y: 0.87500 * height), control2: CGPoint(x: 0.49268 * width, y: 0.87433 * height))
        path.addCurve(to: CGPoint(x: 0.47310 * width, y: 0.86743 * height), control1: CGPoint(x: 0.48318 * width, y: 0.87195 * height), control2: CGPoint(x: 0.47827 * width, y: 0.87009 * height))
        path.addCurve(to: CGPoint(x: 0.32886 * width, y: 0.78381 * height), control1: CGPoint(x: 0.41633 * width, y: 0.83584 * height), control2: CGPoint(x: 0.36825 * width, y: 0.80797 * height))
        path.addCurve(to: CGPoint(x: 0.23446 * width, y: 0.71370 * height), control1: CGPoint(x: 0.28974 * width, y: 0.75966 * height), control2: CGPoint(x: 0.25820 * width, y: 0.73627 * height))
        path.addCurve(to: CGPoint(x: 0.18243 * width, y: 0.64005 * height), control1: CGPoint(x: 0.21067 * width, y: 0.69088 * height), control2: CGPoint(x: 0.19344 * width, y: 0.66633 * height))
        path.addCurve(to: CGPoint(x: 0.16667 * width, y: 0.54647 * height), control1: CGPoint(x: 0.17198 * width, y: 0.61351 * height), control2: CGPoint(x: 0.16667 * width, y: 0.58231 * height))
        path.addLine(to: CGPoint(x: 0.16667 * width, y: 0.24622 * height))
        path.addCurve(to: CGPoint(x: 0.18010 * width, y: 0.20198 * height), control1: CGPoint(x: 0.16667 * width, y: 0.22577 * height), control2: CGPoint(x: 0.17113 * width, y: 0.21101 * height))
        path.addCurve(to: CGPoint(x: 0.21883 * width, y: 0.17810 * height), control1: CGPoint(x: 0.18906 * width, y: 0.19269 * height), control2: CGPoint(x: 0.20199 * width, y: 0.18474 * height))
        path.addCurve(to: CGPoint(x: 0.25793 * width, y: 0.16337 * height), control1: CGPoint(x: 0.22834 * width, y: 0.17397 * height), control2: CGPoint(x: 0.24137 * width, y: 0.16948 * height))
        path.addCurve(to: CGPoint(x: 0.31254 * width, y: 0.14307 * height), control1: CGPoint(x: 0.27450 * width, y: 0.15700 * height), control2: CGPoint(x: 0.29271 * width, y: 0.15023 * height))
        path.addCurve(to: CGPoint(x: 0.37244 * width, y: 0.12158 * height), control1: CGPoint(x: 0.33264 * width, y: 0.13564 * height), control2: CGPoint(x: 0.35261 * width, y: 0.12848 * height))
        path.addCurve(to: CGPoint(x: 0.42745 * width, y: 0.10246 * height), control1: CGPoint(x: 0.39253 * width, y: 0.11442 * height), control2: CGPoint(x: 0.41088 * width, y: 0.10803 * height))
        path.addCurve(to: CGPoint(x: 0.46659 * width, y: 0.08891 * height), control1: CGPoint(x: 0.44402 * width, y: 0.09662 * height), control2: CGPoint(x: 0.45708 * width, y: 0.09209 * height))
        path.addCurve(to: CGPoint(x: 0.48287 * width, y: 0.08492 * height), control1: CGPoint(x: 0.47202 * width, y: 0.08732 * height), control2: CGPoint(x: 0.47744 * width, y: 0.08598 * height))
        path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.08333 * height), control1: CGPoint(x: 0.48858 * width, y: 0.08386 * height), control2: CGPoint(x: 0.49430 * width, y: 0.08333 * height))
        path.closeSubpath()

        let originPath = path
        path = Path()

        path.move(to: CGPoint(x: 0.57296 * width, y: 0.18368 * height))
        path.addCurve(to: CGPoint(x: 0.55379 * width, y: 0.19405 * height), control1: CGPoint(x: 0.56617 * width, y: 0.18341 * height), control2: CGPoint(x: 0.55977 * width, y: 0.18688 * height))
        path.addLine(to: CGPoint(x: 0.32357 * width, y: 0.47636 * height))
        path.addCurve(to: CGPoint(x: 0.31661 * width, y: 0.49231 * height), control1: CGPoint(x: 0.31895 * width, y: 0.48140 * height), control2: CGPoint(x: 0.31661 * width, y: 0.48673 * height))
        path.addCurve(to: CGPoint(x: 0.32194 * width, y: 0.50545 * height), control1: CGPoint(x: 0.31661 * width, y: 0.49762 * height), control2: CGPoint(x: 0.31841 * width, y: 0.50200 * height))
        path.addCurve(to: CGPoint(x: 0.33577 * width, y: 0.51021 * height), control1: CGPoint(x: 0.32574 * width, y: 0.50863 * height), control2: CGPoint(x: 0.33035 * width, y: 0.51021 * height))
        path.addLine(to: CGPoint(x: 0.47839 * width, y: 0.51021 * height))
        path.addLine(to: CGPoint(x: 0.40218 * width, y: 0.70976 * height))
        path.addCurve(to: CGPoint(x: 0.40259 * width, y: 0.73124 * height), control1: CGPoint(x: 0.39866 * width, y: 0.71850 * height), control2: CGPoint(x: 0.39879 * width, y: 0.72568 * height))
        path.addCurve(to: CGPoint(x: 0.41931 * width, y: 0.73999 * height), control1: CGPoint(x: 0.40666 * width, y: 0.73682 * height), control2: CGPoint(x: 0.41225 * width, y: 0.73972 * height))
        path.addCurve(to: CGPoint(x: 0.43848 * width, y: 0.72925 * height), control1: CGPoint(x: 0.42638 * width, y: 0.73999 * height), control2: CGPoint(x: 0.43277 * width, y: 0.73642 * height))
        path.addLine(to: CGPoint(x: 0.66870 * width, y: 0.44690 * height))
        path.addCurve(to: CGPoint(x: 0.67562 * width, y: 0.43099 * height), control1: CGPoint(x: 0.67331 * width, y: 0.44160 * height), control2: CGPoint(x: 0.67562 * width, y: 0.43630 * height))
        path.addCurve(to: CGPoint(x: 0.66992 * width, y: 0.41785 * height), control1: CGPoint(x: 0.67562 * width, y: 0.42568 * height), control2: CGPoint(x: 0.67373 * width, y: 0.42130 * height))
        path.addCurve(to: CGPoint(x: 0.65650 * width, y: 0.41268 * height), control1: CGPoint(x: 0.66639 * width, y: 0.41440 * height), control2: CGPoint(x: 0.66192 * width, y: 0.41268 * height))
        path.addLine(to: CGPoint(x: 0.51383 * width, y: 0.41268 * height))
        path.addLine(to: CGPoint(x: 0.59005 * width, y: 0.21313 * height))
        path.addCurve(to: CGPoint(x: 0.58923 * width, y: 0.19206 * height), control1: CGPoint(x: 0.59358 * width, y: 0.20438 * height), control2: CGPoint(x: 0.59330 * width, y: 0.19736 * height))
        path.addCurve(to: CGPoint(x: 0.57296 * width, y: 0.18368 * height), control1: CGPoint(x: 0.58543 * width, y: 0.18649 * height), control2: CGPoint(x: 0.58001 * width, y: 0.18368 * height))
        path.closeSubpath()

        result.append(
            .subtracting(
                origin: originPath,
                subtracting: path,
                fillColor: colors.icon,
                stroke: colorScheme.stroke(width: width * 0.03)
            )
        )

        return result
    }
}
