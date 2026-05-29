//
//  AmountDirection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

enum SwapAmountDirection {
    case from(Decimal)
    case to(Decimal)

    var amountType: ExpressAmountType {
        switch self {
        case .from(let decimal): .from(decimal)
        case .to(let decimal): .to(decimal)
        }
    }
}
