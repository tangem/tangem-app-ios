//
//  SwappingGasPricePolicy.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum SwappingGasPricePolicy: Hashable, CaseIterable {
    case normal
    case priority

    public func increased(value: Int) -> Int {
        switch self {
        case .normal:
            return value
        case .priority:
            return value * 150 / 100
        }
    }
}
