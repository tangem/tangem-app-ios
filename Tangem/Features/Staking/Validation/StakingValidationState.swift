//
//  StakingValidationState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum StakingValidationState: Hashable {
    case idle
    case validating
    case validated
    case warning
    case blocked

    var allowsSending: Bool {
        switch self {
        case .validated, .warning:
            true
        case .idle, .validating, .blocked:
            false
        }
    }
}
