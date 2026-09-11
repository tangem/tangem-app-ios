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
        let sut = makeModel { SolanaStakingFlowProvider(action: withdraw(), stages: $0, preflightValidator: nil) }
        // Let the init-triggered resolve finish so its in-flight task no longer holds the model.
        _ = try await awaitReady(sut)
        trackForMemoryLeaks(sut)
    }

    @Test("A fixed flow resolves to ready on init")
    func fixedResolvesReady() async throws {
        let model = makeModel(stakingManager: StakingManagerMock(estimateFeeResult: .success(2))) {
            SolanaStakingFlowProvider(action: withdraw(), stages: $0, preflightValidator: nil)
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

    /// [REDACTED_INFO]: tapping Send right after the last keystroke must not stake the previous amount.
    @Test("An amount changed right before Send is the one that reaches the manager")
    func amountChangedRightBeforeSendIsStaked() async throws {
        let manager = StakingManagerMock(estimateFeeResult: .success(1))
        manager.transactionResult = .success(StakingTransactionAction(amount: 0, transactions: []))
        let model = makeModel(stakingManager: manager) {
            EthereumP2PStakingFlowProvider(
                action: StakingAction(amount: 7, targetType: .target(.stub()), type: .unstake),
                stages: $0
            )
        }

        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: 10, fiat: nil)))
        _ = try await awaitReady(model)

        // The recalculation for the new amount is still in flight when Send is tapped.
        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: 4, fiat: nil)))
        _ = try await model.performAction()

        #expect(manager.sentActions.last?.amount == 4)
    }

    @Test("selectedFee reflects the resolved fee")
    func selectedFeeReflectsState() async throws {
        let model = makeModel(stakingManager: StakingManagerMock(estimateFeeResult: .success(3))) {
            SolanaStakingFlowProvider(action: withdraw(), stages: $0, preflightValidator: nil)
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
            SolanaStakingFlowProvider(action: withdraw(), stages: $0, preflightValidator: nil)
        }
        _ = try await awaitReady(model)

        _ = try await model.performAction()

        #expect(dispatcher.sendCalls.count == 1)
        #expect(manager.sentActions.count == 1)
    }

    @Test("performAction aborts, without dispatching, when the real fee exceeds a fee-included estimate")
    func performActionAbortsOnFeeIncrease() async throws {
        let dispatcher = TransactionDispatcherMock()
        let manager = StakingManagerMock(estimateFeeResult: .success(1))
        manager.transactionResult = .success(
            StakingTransactionAction(
                amount: 0,
                transactions: [StakingTransactionInfo(network: "solana", unsignedTransactionData: .raw(""), fee: 5)]
            )
        )
        let model = makeModel(
            stakingManager: manager,
            token: SendStakingableTokenStub(dispatcher: dispatcher),
            feeIncludedCalculator: FeeIncludedCalculatorStub(shouldInclude: true)
        ) {
            SolanaStakingFlowProvider(action: StakingAction(amount: 0, targetType: .empty, type: .stake), stages: $0, preflightValidator: nil)
        }
        model.userDidSelect(target: .stub())
        model.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: 10, fiat: nil)))

        let ready = try await awaitReady(model)
        #expect(ready.isFeeIncluded)

        do {
            _ = try await model.performAction()
            Issue.record("Expected performAction to abort on a fee increase")
        } catch let error as TransactionDispatcherResult.Error {
            guard case .informationRelevanceServiceFeeWasIncreased = error else {
                Issue.record("Unexpected dispatcher error: \(error)")
                return
            }
        }
        #expect(dispatcher.sendCalls.isEmpty)
        #expect(manager.sentActions.isEmpty)
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
        let model = makeModel { SolanaStakingFlowProvider(action: withdraw(), stages: $0, preflightValidator: nil) }
        _ = try await awaitReady(model)

        #expect(throws: SendApproveViewModelInputDataBuilderError.self) {
            _ = try model.approveFlowInput()
        }
    }

    @Test("A blocked validation verdict keeps the summary button disabled on a ready flow")
    func blockedValidationBlocksSending() async throws {
        let manager = StakingManagerMock(estimateFeeResult: .success(1))
        manager.transactionResult = .success(StakingTransactionAction(amount: 0, transactions: []))
        let handler = StakingValidationHandler(
            stakingManager: manager,
            validationProvider: StakingValidationProviderMock(state: .blocked)
        )
        let model = makeModel(stakingManager: manager, validationHandler: handler) {
            SolanaStakingFlowProvider(action: withdraw(), stages: $0, preflightValidator: nil)
        }
        _ = try await awaitReady(model)

        _ = try await handler.validationState.first { $0 == .blocked }.async()
        let isReadyToSend = try await model.isReadyToSendPublisher.first().async()

        #expect(isReadyToSend == false)
    }

    @Test("A blocked validation verdict aborts the send")
    func blockedValidationAbortsSend() async throws {
        let dispatcher = TransactionDispatcherMock()
        let manager = StakingManagerMock(estimateFeeResult: .success(1))
        manager.transactionResult = .success(StakingTransactionAction(amount: 0, transactions: []))
        let handler = StakingValidationHandler(
            stakingManager: manager,
            validationProvider: StakingValidationProviderMock(state: .blocked)
        )
        let model = makeModel(
            stakingManager: manager,
            token: SendStakingableTokenStub(dispatcher: dispatcher),
            validationHandler: handler
        ) {
            SolanaStakingFlowProvider(action: withdraw(), stages: $0, preflightValidator: nil)
        }
        _ = try await awaitReady(model)

        await #expect(throws: (any Error).self) {
            _ = try await model.performAction()
        }
        #expect(dispatcher.sendCalls.isEmpty)
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
        feeIncludedCalculator: FeeIncludedCalculator = FeeIncludedCalculatorStub(),
        validationHandler: StakingValidationHandler? = nil,
        provider: (StakeStagesResolver) -> StakingFlowProvider
    ) -> StakeModel {
        let stages = StakeStagesResolver(
            stakingManager: stakingManager,
            transactionValidator: token.transactionValidator,
            feeIncludedCalculator: feeIncludedCalculator,
            accountInitializationService: nil,
            tokenItem: token.tokenItem,
            feeTokenItem: token.feeTokenItem
        )

        let builtProvider = provider(stages)
        let stepPlan = builtProvider.stepPlan

        return StakeModel(
            provider: builtProvider,
            sendSourceToken: token,
            accountInitializationService: nil,
            validationHandler: validationHandler,
            analyticsLogger: StakeModelAnalyticsLoggerMock(),
            autoupdatingTimer: AutoupdatingTimer(),
            initialAmount: makeInitialAmount(stepPlan: stepPlan, token: token),
            initialTarget: makeInitialTarget(stepPlan: stepPlan, provider: builtProvider),
            shouldUpdateStateInitially: !stepPlan.amount.isEditable && !stepPlan.hasValidatorSelection
        )
    }

    private func makeInitialAmount(stepPlan: StakeStepPlan, token: SendStakingableTokenStub) -> SendAmount? {
        let crypto: Decimal? = switch stepPlan.amount {
        case .editable(let preset): preset
        case .fixed(let value): value
        }
        guard let crypto else { return nil }
        return SendAmount(type: .typical(crypto: crypto, fiat: nil))
    }

    private func makeInitialTarget(stepPlan: StakeStepPlan, provider: StakingFlowProvider) -> LoadingResult<StakingTargetInfo, Never> {
        guard !stepPlan.hasValidatorSelection else { return .loading }
        let baked = provider.makeAction(amount: nil, target: nil).targetType.target
        return baked.map { .success($0) } ?? .loading
    }
}
