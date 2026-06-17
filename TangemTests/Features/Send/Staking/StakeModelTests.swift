//
//  StakeModelTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import TangemStaking
import TangemTestKit
import Testing
@testable import Tangem

@Suite("StakeModel")
final class StakeModelTests: LeakTrackingTestSuite {
    @Test("Deallocates without leaks")
    func noLeaks() async throws {
        let sut = makeModel { SolanaStakingFlowProvider(action: withdraw(), stages: $0) }
        // Let the init-triggered resolve finish so its in-flight task no longer holds the model.
        _ = try await awaitReady(sut)
        trackForMemoryLeaks(sut)
    }

    @Test("A fixed flow resolves to ready on init")
    func fixedResolvesReady() async throws {
        let model = makeModel(stakingManager: StakingManagerMock(estimateFeeResult: .success(2))) {
            SolanaStakingFlowProvider(action: withdraw(), stages: $0)
        }

        let ready = try await awaitReady(model)
        #expect(ready.fee == 2)
    }

    @Test("An editable flow resolves once an amount is entered")
    func editableResolvesAfterAmount() async throws {
        // P2P partial unstake: amount is editable, the target rides on the action (no validator step to wait for).
        let model = makeModel(stakingManager: StakingManagerMock(estimateFeeResult: .success(1))) {
            EthereumP2PStakingFlowProvider(
                action: StakingAction(amount: 7, targetType: .target(.stub()), type: .unstake),
                stages: $0
            )
        }
        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: 10, fiat: nil)))

        let ready = try await awaitReady(model)
        #expect(ready.amount == 10)
    }

    @Test("selectedFee reflects the resolved fee")
    func selectedFeeReflectsState() async throws {
        let model = makeModel(stakingManager: StakingManagerMock(estimateFeeResult: .success(3))) {
            SolanaStakingFlowProvider(action: withdraw(), stages: $0)
        }
        _ = try await awaitReady(model)

        guard case .success(let fee)? = model.selectedFee?.value else {
            Issue.record("Expected a resolved fee")
            return
        }
        #expect(fee.amount.value == 3)
    }

    @Test("performAction sends the staking transaction and notifies the manager")
    func performActionSends() async throws {
        let dispatcher = TransactionDispatcherMock()
        let manager = StakingManagerMock(estimateFeeResult: .success(1))
        manager.transactionResult = .success(StakingTransactionAction(amount: 0, transactions: []))
        let model = makeModel(stakingManager: manager, token: SendStakingableTokenStub(dispatcher: dispatcher)) {
            SolanaStakingFlowProvider(action: withdraw(), stages: $0)
        }
        _ = try await awaitReady(model)

        _ = try await model.performAction()

        #expect(dispatcher.sendCalls.count == 1)
        #expect(manager.sentActions.count == 1)
    }

    @Test("performAction throws when the state is not ready")
    func performActionNotReady() async {
        // Editable flow with no amount entered never leaves loading.
        let model = makeModel {
            EthereumP2PStakingFlowProvider(action: StakingAction(amount: 0, targetType: .empty, type: .stake), stages: $0)
        }

        await #expect(throws: StakeModelError.self) {
            _ = try await model.performAction()
        }
    }

    @Test("approveFlowInput throws when the flow is not awaiting an approval")
    func approveFlowInputThrowsWhenNotApprove() async throws {
        let model = makeModel { SolanaStakingFlowProvider(action: withdraw(), stages: $0) }
        _ = try await awaitReady(model)

        #expect(throws: SendApproveViewModelInputDataBuilderError.self) {
            _ = try model.approveFlowInput()
        }
    }

    // MARK: - Helpers

    private func awaitReady(_ model: StakeModel) async throws -> StakeFlowState.Ready {
        try await withThrowingTaskGroup(of: StakeFlowState.Ready.self) { group in
            group.addTask {
                try await model.statePublisher
                    .compactMap { state -> StakeFlowState.Ready? in
                        if case .ready(let ready) = state { ready } else { nil }
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

    private struct TimeoutError: Error {}

    private func withdraw() -> StakingAction {
        StakingAction(amount: 10, targetType: .empty, type: .pending(.withdraw(passthroughs: ["p"])))
    }

    private func makeModel(
        stakingManager: StakingManagerMock = StakingManagerMock(estimateFeeResult: .success(1)),
        token: SendStakingableTokenStub = SendStakingableTokenStub(),
        provider: (StakingFlowStages) -> StakingFlowProvider
    ) -> StakeModel {
        let stages = StakingFlowStages(
            stakingManager: stakingManager,
            transactionValidator: token.transactionValidator,
            feeIncludedCalculator: FeeIncludedCalculatorStub(),
            accountInitializationService: nil,
            tokenItem: token.tokenItem,
            feeTokenItem: token.feeTokenItem
        )

        return StakeModel(
            provider: provider(stages),
            stakingManager: stakingManager,
            sendSourceToken: token,
            accountInitializationService: nil,
            analyticsLogger: StakeModelAnalyticsLoggerMock()
        )
    }
}
