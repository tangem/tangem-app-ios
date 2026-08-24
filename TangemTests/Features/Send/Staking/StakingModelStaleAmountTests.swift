//
//  StakingModelStaleAmountTests.swift
//  TangemTests
//
//  Created for [REDACTED_INFO].
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import TangemStaking
import Testing
@testable import Tangem

/// Guards [REDACTED_INFO]: the V1 staking model never recalculated on an amount change — only entering the summary
/// screen forced it — so a Send fired right after the last keystroke staked the previous amount.
@Suite("StakingModel stale amount")
struct StakingModelStaleAmountTests {
    @Test("An amount change recalculates the state", .timeLimit(.minutes(1)))
    func amountChangeRecalculatesState() async throws {
        let manager = StakingManagerMock(estimateFeeResult: .success(1))
        let model = makeModel(stakingManager: manager)

        model.userDidSelect(target: .stub())
        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: 10, fiat: nil)))

        let ready = try await awaitReadyToStake(model)
        #expect(ready.amount == 10)
    }

    @Test("An amount changed right before Send is the one that reaches the manager", .timeLimit(.minutes(1)))
    func amountChangedRightBeforeSendIsStaked() async throws {
        let manager = StakingManagerMock(estimateFeeResult: .success(1))
        manager.transactionResult = .success(StakingTransactionAction(amount: 0, transactions: []))
        let model = makeModel(stakingManager: manager)

        model.userDidSelect(target: .stub())
        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: 10, fiat: nil)))
        _ = try await awaitReadyToStake(model)

        // The recalculation for the new amount is still in flight when Send is tapped.
        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: 4, fiat: nil)))
        _ = try await model.performAction()

        #expect(manager.sentActions.last?.amount == 4)
    }
}

// MARK: - Helpers

private extension StakingModelStaleAmountTests {
    func makeModel(stakingManager: StakingManagerMock) -> StakingModel {
        StakingModel(
            stakingManager: stakingManager,
            sendSourceToken: SendStakingableTokenStub(dispatcher: TransactionDispatcherMock()),
            feeIncludedCalculator: FeeIncludedCalculatorStub(),
            analyticsLogger: StakingSendAnalyticsLoggerMock(),
            accountInitializationService: nil,
            minimalBalanceProvider: nil,
            validationHandler: nil
        )
    }

    func awaitReadyToStake(_ model: StakingModel) async throws -> StakingModel.State.ReadyToStake {
        try await withThrowingTaskGroup(of: StakingModel.State.ReadyToStake.self) { group in
            group.addTask {
                try await model.state
                    .compactMap { state -> StakingModel.State.ReadyToStake? in
                        if case .readyToStake(let ready) = state { ready } else { nil }
                    }
                    .first()
                    .async()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(5))
                throw TimeoutError()
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    struct TimeoutError: Error {}
}
