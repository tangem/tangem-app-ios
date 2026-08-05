//
//  TokenIconV2Size.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

public extension TokenIconV2 {
    enum Size: CaseIterable, Hashable, Sendable {
        case size40
        case size44
        case size56
        case size72

        public var containerSize: CGSize {
            switch self {
            case .size40: return .init(bothDimensions: 40)
            case .size44: return .init(bothDimensions: 44)
            case .size56: return .init(bothDimensions: 56)
            case .size72: return .init(bothDimensions: 72)
            }
        }
    }
}

extension TokenIconV2.Size {
    var baseMetrics: TokenIconV2.Metrics {
        switch self {
        case .size40:
            TokenIconV2.Metrics(
                container: containerSize.width,
                networkDiameter: 12,
                networkOverhang: 1,
                cutoutGap: 1,
                indicatorDiameter: 6,
                indicatorInset: 3
            )
        case .size44:
            TokenIconV2.Metrics(
                container: containerSize.width,
                networkDiameter: 16,
                networkOverhang: 2,
                cutoutGap: 1,
                indicatorDiameter: 6,
                indicatorInset: 4
            )
        case .size56:
            TokenIconV2.Metrics(
                container: containerSize.width,
                networkDiameter: 20,
                networkOverhang: 4,
                cutoutGap: 1,
                indicatorDiameter: 6,
                indicatorInset: 5
            )
        case .size72:
            TokenIconV2.Metrics(
                container: containerSize.width,
                networkDiameter: 24,
                networkOverhang: 4,
                cutoutGap: 1,
                indicatorDiameter: 8,
                indicatorInset: 6
            )
        }
    }
}

extension TokenIconV2 {
    struct Metrics {
        let container: CGFloat
        let networkDiameter: CGFloat
        let networkOverhang: CGFloat
        let cutoutGap: CGFloat
        let indicatorDiameter: CGFloat
        let indicatorInset: CGFloat

        var cutoutDiameter: CGFloat {
            networkDiameter + 2 * cutoutGap
        }

        var indicatorCutoutDiameter: CGFloat {
            indicatorDiameter + 2 * cutoutGap
        }

        func scaled(by factor: CGFloat) -> Metrics {
            Metrics(
                container: container * factor,
                networkDiameter: networkDiameter * factor,
                networkOverhang: networkOverhang * factor,
                cutoutGap: cutoutGap * factor,
                indicatorDiameter: indicatorDiameter * factor,
                indicatorInset: indicatorInset * factor
            )
        }
    }
}
