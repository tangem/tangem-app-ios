//
//  AllowanceServiceMock.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
@testable import Tangem

final class AllowanceServiceMock: AllowanceService {
    private struct State {
        var allowanceStateResult: Result<AllowanceState, Error> = .success(.enoughAllowance)
        var allowanceStateResultsByPolicy: [ApprovePolicy: Result<AllowanceState, Error>] = [:]
        var shouldHoldNextAllowanceStateCall = false
        var heldCallsAreReleased = false
        var heldCallContinuations: [CheckedContinuation<Void, Never>] = []
        var allowanceStateCalls: [(amount: Decimal, spender: String, approvePolicy: ApprovePolicy)] = []
        var markApproveTransactionSentCalls: [String] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    // MARK: - Stubs

    var allowanceStateResult: Result<AllowanceState, Error> {
        get { state { $0.allowanceStateResult } }
        set { state { $0.allowanceStateResult = newValue } }
    }

    func setAllowanceStateResult(_ result: Result<AllowanceState, Error>, for policy: ApprovePolicy) {
        state { $0.allowanceStateResultsByPolicy[policy] = result }
    }

    // MARK: - Gate

    func holdNextAllowanceStateCall() {
        state { state in
            state.shouldHoldNextAllowanceStateCall = true
            state.heldCallsAreReleased = false
        }
    }

    func releaseHeldAllowanceStateCalls() {
        let continuations = state { state in
            state.heldCallsAreReleased = true
            let held = state.heldCallContinuations
            state.heldCallContinuations = []
            return held
        }

        continuations.forEach { $0.resume() }
    }

    // MARK: - Call tracking

    var allowanceStateCalls: [(amount: Decimal, spender: String, approvePolicy: ApprovePolicy)] {
        state { $0.allowanceStateCalls }
    }

    var markApproveTransactionSentCalls: [String] {
        state { $0.markApproveTransactionSentCalls }
    }

    // MARK: - AllowanceService

    func allowanceState(amount: Decimal, spender: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState {
        let shouldHold = state { state in
            state.allowanceStateCalls.append((amount, spender, approvePolicy))
            let shouldHold = state.shouldHoldNextAllowanceStateCall
            state.shouldHoldNextAllowanceStateCall = false
            return shouldHold
        }

        if shouldHold {
            await withCheckedContinuation { continuation in
                let resumeImmediately = state { state in
                    if state.heldCallsAreReleased {
                        return true
                    }

                    state.heldCallContinuations.append(continuation)
                    return false
                }

                if resumeImmediately {
                    continuation.resume()
                }
            }
        }

        let result = state { $0.allowanceStateResultsByPolicy[approvePolicy] ?? $0.allowanceStateResult }
        return try result.get()
    }

    func markApproveTransactionSent(spender: String) async {
        state { $0.markApproveTransactionSentCalls.append(spender) }
    }

    func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) async throws -> ApproveTransactionData {
        ApproveTransactionData(txData: Data(), spender: spender, toContractAddress: "")
    }
}
