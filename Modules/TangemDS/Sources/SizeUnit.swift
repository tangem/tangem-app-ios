//
//  SizeUnit.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum SizeUnit {
    case zero, half
    case x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, x17, x18

    var value: CGFloat {
        baseValue * factor
    }

    private let baseValue: CGFloat = 4

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
