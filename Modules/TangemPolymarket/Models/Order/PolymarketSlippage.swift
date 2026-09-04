//
//  PolymarketSlippage.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketSlippage {
    public static let defaultPercent: Decimal = 0.25
    public static let minPercent: Decimal = 0.1
    public static let maxPercent: Decimal = 30

    public static let fractionDigits = 2

    public static let presets: [Preset] = [
        Preset(percent: defaultPercent, role: .default),
        Preset(percent: 0.1, role: .plain),
        Preset(percent: 0.5, role: .plain),
        Preset(percent: 1, role: .plain),
        Preset(percent: 2, role: .plain),
        Preset(percent: 3, role: .max),
    ]

    public static func accepts(_ percent: Decimal) -> Bool {
        percent >= minPercent && percent <= maxPercent
    }

    public static func isDefault(_ percent: Decimal) -> Bool {
        percent == defaultPercent
    }
}

// MARK: - Preset

public extension PolymarketSlippage {
    struct Preset: Hashable, Identifiable {
        public let percent: Decimal
        public let role: Role

        public var id: Decimal { percent }

        public init(percent: Decimal, role: Role) {
            self.percent = percent
            self.role = role
        }
    }

    enum Role: Hashable {
        case `default`
        case plain
        case max
    }
}
