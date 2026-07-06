//
//  GlowEasing.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum GlowEasing {
    case linear
    case easeInOut
    case custom(Double, Double, Double, Double)

    func value(_ x: Double) -> Double {
        switch self {
        case .linear: x
        case .easeInOut:
            UnitBezier(x1: 0.42, y1: 0, x2: 0.58, y2: 1).value(x)
        case .custom(let a, let b, let c, let d):
            UnitBezier(x1: a, y1: b, x2: c, y2: d).value(x)
        }
    }
}
