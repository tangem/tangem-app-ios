//
//  ExpressManagerUpdatingType.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public enum ExpressManagerUpdatingType {
    case amount
    case autoupdate
    case pair

    public var isRequiredUpdateSelectedProvider: Bool {
        switch self {
        case .amount, .pair: true
        case .autoupdate: false
        }
    }
}
