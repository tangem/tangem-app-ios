//
//  StakingModelCancellationTests.swift
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

@Suite("Staking models ignore cancelled fee updates")
final class StakingModelCancellationTests: LeakTrackingTestSuite {
    private let blockchain = Blockchain.solana(curve: .ed25519_slip0010, testnet: false)

    private var tokenItem: TokenItem { .blockchain(.init(blockchain, derivationPath: nil)) }

    @Test("StakingSingleActionModel does not publish networkError when fee estimation is cancelled")
    func singleActionModelIgnoresCancelledFeeEstimation() async throws {
        let (estimationStarted, stakingManager) = makeHangingFirstCallStakingManager()
        let model = makeSingleActionModel(stakingManager: stakingManager, preflightValidator: nil)
        let recordedStates = recordStates(of: model.statePublisher)

        var estimationStartedIterator = estimationStarted.makeAsyncIterator()
        await estimationStartedIterator.next()

        model.updateFees()

        try await waitUntilReady(state: { model.state })
        try await Task.sleep(nanoseconds: 100_000_000)

        assertNoErrorStates(in: recordedStates.states.withLock { $0 })
        withExtendedLifetime(recordedStates.cancellable) {}
    }

    @Test("StakingSingleActionModel does not publish stale preflight result from a cancelled task")
    func singleActionModelIgnoresCancelledPreflight() async throws {
        let stakingManager = StakingManagerStub()
        stakingManager.estimateFeeBody = { _ in 0.000005 }

        let (preflightStarted, preflightValidator) = makeHangingFirstCallPreflightValidator()
        let model = makeSingleActionModel(stakingManager: stakingManager, preflightValidator: preflightValidator)
        let recordedStates = recordStates(of: model.statePublisher)

        var preflightStartedIterator = preflightStarted.makeAsyncIterator()
        await preflightStartedIterator.next()

        model.updateFees()

        try await waitUntilReady(state: { model.state })
        try await Task.sleep(nanoseconds: 100_000_000)

        assertNoErrorStates(in: recordedStates.states.withLock { $0 })
        withExtendedLifetime(recordedStates.cancellable) {}
    }

    @Test("UnstakingModel does not publish networkError when fee estimation is cancelled")
    func unstakingModelIgnoresCancelledFeeEstimation() async throws {
        let (estimationStarted, stakingManager) = makeHangingFirstCallStakingManager()
        let model = makeUnstakingModel(stakingManager: stakingManager, preflightValidator: nil)
        let recordedStates = recordStates(of: model.statePublisher)

        var estimationStartedIterator = estimationStarted.makeAsyncIterator()
        await estimationStartedIterator.next()

        model.updateFees()

        try await waitUntilReady(state: { model.state })
        try await Task.sleep(nanoseconds: 100_000_000)

        assertNoErrorStates(in: recordedStates.states.withLock { $0 })
        withExtendedLifetime(recordedStates.cancellable) {}
    }

    @Test("UnstakingModel does not publish stale preflight result from a cancelled task")
    func unstakingModelIgnoresCancelledPreflight() async throws {
        let stakingManager = StakingManagerStub()
        stakingManager.estimateFeeBody = { _ in 0.000005 }

        let (preflightStarted, preflightValidator) = makeHangingFirstCallPreflightValidator()
        let model = makeUnstakingModel(stakingManager: stakingManager, preflightValidator: preflightValidator)
        let recordedStates = recordStates(of: model.statePublisher)

        var preflightStartedIterator = preflightStarted.makeAsyncIterator()
        await preflightStartedIterator.next()

        model.updateFees()

        try await waitUntilReady(state: { model.state })
        try await Task.sleep(nanoseconds: 100_000_000)

        assertNoErrorStates(in: recordedStates.states.withLock { $0 })
        withExtendedLifetime(recordedStates.cancellable) {}
    }
}

// MARK: - Assertions

private extension StakingModelCancellationTests {
    func assertNoErrorStates(in states: [UnstakingModel.State]) {
        let hasReadyState = states.contains { state in
            if case .ready = state {
                return true
            }
            return false
        }
        #expect(hasReadyState)

        for state in states {
            switch state {
            case .networkError(let error):
                Issue.record("Cancelled task leaked networkError: \(error)")
            case .validationError(let error, _):
                Issue.record("Cancelled task leaked validationError: \(error)")
            case .loading, .ready:
                break
            }
        }
    }
}

// MARK: - Factories

private extension StakingModelCancellationTests {
    func makeSingleActionModel(
        stakingManager: StakingManager,
        preflightValidator: StakingPreflightValidator?
    ) -> StakingSingleActionModel {
        let model = StakingSingleActionModel(
            stakingManager: stakingManager,
            sendSourceToken: makeSendSourceToken(),
            analyticsLogger: StakingSendAnalyticsLoggerMock(),
            action: StakingAction(amount: 0.02, targetType: .empty, type: .pending(.withdraw(passthroughs: []))),
            validationHandler: nil,
            preflightValidator: preflightValidator
        )
        return trackForMemoryLeaks(model)
    }

    func makeUnstakingModel(
        stakingManager: StakingManager,
        preflightValidator: StakingPreflightValidator?
    ) -> UnstakingModel {
        let model = UnstakingModel(
            stakingManager: stakingManager,
            sendSourceToken: makeSendSourceToken(),
            analyticsLogger: StakingSendAnalyticsLoggerMock(),
            action: StakingAction(amount: 1, targetType: .empty, type: .unstake),
            validationHandler: nil,
            preflightValidator: preflightValidator
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

    /// The first call reports that it has started, then hangs until its task is cancelled
    /// and throws the same error flavor URLSession produces for a cancelled request.
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

private extension StakingModelCancellationTests {
    func recordStates(
        of publisher: AnyPublisher<UnstakingModel.State, Never>
    ) -> (states: OSAllocatedUnfairLock<[UnstakingModel.State]>, cancellable: AnyCancellable) {
        let states = OSAllocatedUnfairLock(initialState: [UnstakingModel.State]())
        let cancellable = publisher.sink { state in
            states.withLock { $0.append(state) }
        }
        return (states, cancellable)
    }

    func waitUntilReady(state: () -> UnstakingModel.State) async throws {
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
