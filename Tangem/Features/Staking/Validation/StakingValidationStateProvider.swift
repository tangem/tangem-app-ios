//
//  StakingValidationStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Provides transaction validation state for staking flows.
/// Separate from StakingModelStateProvider to follow OCP - existing code doesn't need modification.
protocol StakingValidationStateProvider {
    var validationState: AnyPublisher<StakingValidationState, Never> { get }
}
