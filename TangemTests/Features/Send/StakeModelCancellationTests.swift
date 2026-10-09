//
//  StakeModelCancellationTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemFoundation
import TangemTestKit
@testable import TangemStaking
@testable import Tangem

@Suite("StakeModel ignores cancelled fee updates")
final class StakeModelCancellationTests: LeakTrackingTestSuite {
    private let blockchain = Blockchain.solana(curve: .ed25519_slip0010, testnet: false)

    private var tokenItem: TokenItem { .blockchain(.init(blockchain, derivationPath: nil)) }

    @Test("StakeModel does not publish a network failure when fee estimation is cancelled", .timeLimit(.minutes(1)))
    func ignoresCancelledFeeEstimation() async throws {
        let (estimationStarted, stakingManager) = makeHangingFirstCallStakingManager()
        let model = makeModel(stakingManager: stakingManager, preflightValidator: nil)
        let recordedStates = recordStates(of: model.statePublisher)

        var estimationStartedIterator = estimationStarted.makeAsyncIterator()
        await estimationStartedIterator.next()

        model.updateFees()

        try await waitUntilReady(state: { model.state })
        try await Task.sleep(nanoseconds: 100_000_000)

        assertNoFailureStates(in: recordedStates.states.withLock { $0 })
        withExtendedLifetime(recordedStates.cancellable) {}
    }

    @Test("StakeModel does not publish a stale preflight result from a cancelled task", .timeLimit(.minutes(1)))
    func ignoresCancelledPreflight() async throws {
        let stakingManager = StakingManagerStub()
        stakingManager.estimateFeeBody = { _ in 0.000005 }

        let (preflightStarted, preflightValidator) = makeHangingFirstCallPreflightValidator()
        let model = makeModel(stakingManager: stakingManager, preflightValidator: preflightValidator)
        let recordedStates = recordStates(of: model.statePublisher)

        var preflightStartedIterator = preflightStarted.makeAsyncIterator()
        await preflightStartedIterator.next()

        model.updateFees()

        try await waitUntilReady(state: { model.state })
        try await Task.sleep(nanoseconds: 100_000_000)

        assertNoFailureStates(in: recordedStates.states.withLock { $0 })
        withExtendedLifetime(recordedStates.cancellable) {}
    }
}

// MARK: - Assertions

private extension StakeModelCancellationTests {
    func assertNoFailureStates(in states: [StakeFlowState]) {
        let hasReadyState = states.contains { state in
            if case .ready = state {
                return true
            }
            return false
        }
        #expect(hasReadyState)

        for state in states {
            switch state {
            case .failure(.network(let error)):
                Issue.record("Cancelled task leaked a network failure: \(error)")
            case .failure(.transaction(let error, _, _)):
                Issue.record("Cancelled task leaked a transaction failure: \(error)")
            case .failure(.staking(let error)):
                Issue.record("Cancelled task leaked a staking failure: \(error)")
            case .loading, .ready, .prerequisite:
                break
            }
        }
    }
}

// MARK: - Factories

private extension StakeModelCancellationTests {
    func makeModel(
        stakingManager: StakingManager,
        preflightValidator: StakingPreflightValidator?
    ) -> StakeModel {
        let sourceToken = makeSendSourceToken()
        let action = StakingAction(amount: 0.02, targetType: .empty, type: .pending(.withdraw(passthroughs: [])))
        let stages = StakeStagesResolver(
            stakingManager: stakingManager,
            transactionValidator: sourceToken.transactionValidator,
            feeIncludedCalculator: FeeIncludedCalculatorStub(),
            accountInitializationService: nil,
            tokenItem: sourceToken.tokenItem,
            feeTokenItem: sourceToken.feeTokenItem
        )

        let model = StakeModel(
            provider: SolanaStakingFlowProvider(action: action, stages: stages, preflightValidator: preflightValidator),
            sendSourceToken: sourceToken,
            accountInitializationService: nil,
            validationHandler: nil,
            analyticsLogger: StakeModelAnalyticsLoggerMock(),
            autoupdatingTimer: AutoupdatingTimer(),
            initialAmount: SendAmount(type: .typical(crypto: action.amount, fiat: nil)),
            initialTarget: .loading
        )
        return trackForMemoryLeaks(model)
    }

    func makeSendSourceToken() -> SendTransferableTokenStub {
        let feeProvider = TokenFeeProviderStub(
            feeTokenItem: tokenItem,
            initialFee: TokenFee(option: .market, tokenItem: tokenItem, value: .loading)
        )
        return SendTransferableTokenStub(
            blockchain: blockchain,
            tokenFeeProvidersManager: TokenFeeProvidersManagerMock(feeProvider: feeProvider)
        )
    }

    func makeHangingFirstCallStakingManager() -> (started: AsyncStream<Void>, manager: StakingManagerStub) {
        let (started, startedContinuation) = AsyncStream<Void>.makeStream()

        let stakingManager = StakingManagerStub()
        stakingManager.estimateFeeBody = { callIndex in
            guard callIndex == 0 else {
                return 0.000005
            }

            startedContinuation.yield()
            while !Task.isCancelled {
                await Task.yield()
            }
            throw URLError(.cancelled)
        }

        return (started, stakingManager)
    }

    func makeHangingFirstCallPreflightValidator() -> (started: AsyncStream<Void>, validator: PreflightValidatorStub) {
        let (started, startedContinuation) = AsyncStream<Void>.makeStream()

        let validator = PreflightValidatorStub()
        validator.validateBody = { [blockchain] callIndex in
            guard callIndex == 0 else {
                return nil
            }

            startedContinuation.yield()
            while !Task.isCancelled {
                await Task.yield()
            }

            let minimumBalance = BSDKAmount(with: blockchain, value: Decimal(string: "0.00089088")!)
            return StakingPreflightFailure(
                validationError: .remainingAmountIsLessThanRentExemption(amount: minimumBalance),
                estimatedFee: 0.000005
            )
        }

        return (started, validator)
    }
}

// MARK: - Helpers

private extension StakeModelCancellationTests {
    func recordStates(
        of publisher: AnyPublisher<StakeFlowState, Never>
    ) -> (states: OSAllocatedUnfairLock<[StakeFlowState]>, cancellable: AnyCancellable) {
        let states = OSAllocatedUnfairLock(initialState: [StakeFlowState]())
        let cancellable = publisher.sink { state in
            states.withLock { $0.append(state) }
        }
        return (states, cancellable)
    }

    func waitUntilReady(state: () -> StakeFlowState) async throws {
        for _ in 0 ..< 200 {
            if case .ready = state() {
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        Issue.record("Timed out waiting for the ready state, last state: \(state())")
    }
}

// MARK: - Stubs

private final class StakingManagerStub: StakingManager {
    var estimateFeeBody: (@Sendable (_ callIndex: Int) async throws -> Decimal)?

    private let callCounter = OSAllocatedUnfairLock(initialState: 0)

    var state: StakingManagerState { .notEnabled }
    var balances: [StakingBalance]? { nil }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { Just(.notEnabled).eraseToAnyPublisher() }
    var updateWalletBalancesPublisher: AnyPublisher<Void, Never> { Just(()).eraseToAnyPublisher() }
    var allowanceAddress: String? { nil }
    var tosURL: URL { URL(string: "https://example.com")! }
    var privacyPolicyURL: URL { URL(string: "https://example.com")! }

    func updateState(loadActions: Bool, source: StakingUpdateSource) async {}

    func estimateFee(action: StakingAction) async throws -> Decimal {
        guard let estimateFeeBody else {
            throw NSError(domain: "StakingManagerStub", code: 0)
        }

        let callIndex = callCounter.withLock { counter in
            let current = counter
            counter += 1
            return current
        }

        return try await estimateFeeBody(callIndex)
    }

    func transaction(action: StakingAction) async throws -> StakingTransactionAction {
        throw NSError(domain: "StakingManagerStub", code: 0)
    }

    func transactionDidSent(action: StakingAction) {}
}

private final class PreflightValidatorStub: StakingPreflightValidator {
    var validateBody: (@Sendable (_ callIndex: Int) async -> StakingPreflightFailure?)?

    private let callCounter = OSAllocatedUnfairLock(initialState: 0)

    func validate() async -> StakingPreflightFailure? {
        guard let validateBody else {
            return nil
        }

        let callIndex = callCounter.withLock { counter in
            let current = counter
            counter += 1
            return current
        }

        return await validateBody(callIndex)
    }
}
