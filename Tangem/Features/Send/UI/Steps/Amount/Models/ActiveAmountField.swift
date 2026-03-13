//
//  ActiveAmountField.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum ActiveAmountField: Hashable {
    case send
    case receive

    var opposite: ActiveAmountField {
        switch self {
        case .send: return .receive
        case .receive: return .send
        }
    }
}
