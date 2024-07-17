//
//  StakingManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class StakingManagerMock: StakingManager {
    var state: StakingManagerState { .notEnabled }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { .just(output: state) }

    func updateState() {}

    func getFee(amount: Decimal, validator: String) async throws -> Decimal { 0.12345 }

    func getTransaction() async throws {}
}
