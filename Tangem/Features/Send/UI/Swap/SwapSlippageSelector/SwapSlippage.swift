//
//  SwapSlippage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum SwapSlippage: Hashable {
    case auto
    case custom(Decimal)
}

// MARK: - Express

extension SwapSlippage {
    init(expressSlippage: Decimal?) {
        self = expressSlippage.map { .custom($0) } ?? .auto
    }

    var expressSlippage: Decimal? {
        switch self {
        case .auto: nil
        case .custom(let value): value
        }
    }
}
