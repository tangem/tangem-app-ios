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
        case .easeInOut: UnitBezier(0.42, 0, 0.58, 1).value(x)
        case .custom(let a, let b, let c, let d): UnitBezier(a, b, c, d).value(x)
        }
    }
}
