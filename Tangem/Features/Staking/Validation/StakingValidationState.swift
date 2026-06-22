//
//  StakingValidationState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validation state for staking transactions.
/// Separate enum to avoid modifying StakingModel.State.
enum StakingValidationState: Hashable {
    case idle
    case validating
    case validated
    case warning
    case blocked
}
