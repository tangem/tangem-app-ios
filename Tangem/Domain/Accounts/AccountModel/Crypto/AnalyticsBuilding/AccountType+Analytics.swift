//
//  AccountType+Analytics.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension AccountType {
    var analyticsValue: Analytics.ParameterValue {
        switch self {
        case .crypto: .accountTypeCrypto
        case .joint: .accountTypeJoint
        case .collectibles: .accountTypeCollectibles
        }
    }
}
