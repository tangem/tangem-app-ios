//
//  StakingPreflightValidator.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol StakingPreflightValidator {
    func validate() async -> StakingPreflightFailure?
}

struct StakingPreflightFailure {
    let validationError: ValidationError
    let estimatedFee: Decimal
}
