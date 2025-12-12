//
//  StakingTargetsInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingTargetsInput: AnyObject {
    var selectedTarget: StakingTargetInfo? { get }
    var selectedTargetPublisher: AnyPublisher<StakingTargetInfo, Never> { get }
}

protocol StakingTargetsOutput: AnyObject {
    func userDidSelect(target: StakingTargetInfo)
}
