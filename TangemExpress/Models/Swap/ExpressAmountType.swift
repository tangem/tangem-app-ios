//
//  ExpressAmountType.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressAmountType {
    case from(Decimal)
    case to(Decimal)

    public var amount: Decimal {
        switch self {
        case .from(let value), .to(let value):
            return value
        }
    }
}
