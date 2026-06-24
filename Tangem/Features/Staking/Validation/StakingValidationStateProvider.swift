//
//  StakingValidationStateProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol StakingValidationStateProvider {
    var validationState: AnyPublisher<StakingValidationState, Never> { get }
}
