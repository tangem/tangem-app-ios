//
//  SizeUnit.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum SizeUnit {
    case zero
    case half
    case x1
    case x2
    case x3
    case x4
    case x5
    case x6
    case x7
    case x8
    case x9
    case x10
    case x11
    case x12
    case x13
    case x14
    case x15
    case x16
    case x17
    case x18

    var value: CGFloat {
        Self.baseValue * factor
    }

    private static let baseValue: CGFloat = 4

    private var factor: Double {
        switch self {
        case .zero: 0
        case .half: 0.5
        case .x1: 1
        case .x2: 2
        case .x3: 3
        case .x4: 4
        case .x5: 5
        case .x6: 6
        case .x7: 7
        case .x8: 8
        case .x9: 9
        case .x10: 10
        case .x11: 11
        case .x12: 12
        case .x13: 13
        case .x14: 14
        case .x15: 15
        case .x16: 16
        case .x17: 17
        case .x18: 18
        }
    }
}

public extension CGFloat {
    static func unit(_ size: SizeUnit) -> CGFloat {
        size.value
    }
}
