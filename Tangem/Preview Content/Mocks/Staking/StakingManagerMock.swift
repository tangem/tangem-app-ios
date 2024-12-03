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
    var balances: [TangemStaking.StakingBalance]? = []
    var statePublisher: AnyPublisher<StakingManagerState, Never> { .just(output: state) }
    var allowanceAddress: String? { nil }

    func updateState(loadActions: Bool) async {}
    func estimateFee(action: StakingAction) async throws -> Decimal { .zero }
    func transaction(action: StakingAction) async throws -> StakingTransactionAction { .mock }
    func transactionDidSent(action: StakingAction) {}
}
