//
//  StakingValidatorsInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingValidatorsInput: AnyObject {
    var selectedValidator: ValidatorInfo? { get }
    var selectedValidatorPublisher: AnyPublisher<ValidatorInfo, Never> { get }
}

protocol StakingValidatorsOutput: AnyObject {
    func userDidSelected(validator: ValidatorInfo)
}
