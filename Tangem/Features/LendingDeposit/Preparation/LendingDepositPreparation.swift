//
//  LendingDepositPreparation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum LendingDepositPreparation: Equatable {
    case deployModule
    case initializeToken(upgradeImplementation: String?)
    case reactivateToken(upgradeImplementation: String?)

    var upgradeImplementation: String? {
        switch self {
        case .deployModule: nil
        case .initializeToken(let upgradeImplementation), .reactivateToken(let upgradeImplementation): upgradeImplementation
        }
    }
}
