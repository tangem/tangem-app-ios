//
//  StakeFlowStatePresentationTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import Testing
@testable import Tangem

@Suite("StakeFlowState presentation")
struct StakeFlowStatePresentationTests {
    @Test("isReadyToSend is true only for ready and readyToApprove")
    func isReadyToSend() {
        #expect(ready().isReadyToSend)
        #expect(StakeFlowState.prerequisite(.approve(.required(approveData(), stakingFee: 1))).isReadyToSend)

        #expect(!StakeFlowState.loading.isReadyToSend)
        #expect(!StakeFlowState.prerequisite(.approve(.inProgress(stakingFee: 1))).isReadyToSend)
        #expect(!StakeFlowState.failure(.network(SampleError.any)).isReadyToSend)
        #expect(!StakeFlowState.prerequisite(.accountInitialization(.required(initializationFee: fee(0.5), transactionFee: fee(1)))).isReadyToSend)
        #expect(!StakeFlowState.prerequisite(.accountInitialization(.inProgress)).isReadyToSend)
    }

    @Test("Fee presentation shows the fee for ready / approve / account-init-required / transaction failure")
    func feeValue() {
        expectFee(ready(fee: 2), equals: 2)
        expectFee(.prerequisite(.approve(.required(approveData(), stakingFee: 3))), equals: 3)
        expectFee(.prerequisite(.approve(.inProgress(stakingFee: 4))), equals: 4)
        // For account-init-required the *transaction* fee is shown, not the initialization fee.
        expectFee(.prerequisite(.accountInitialization(.required(initializationFee: fee(0.5), transactionFee: fee(5)))), equals: 5)
        expectFee(.failure(.transaction(.totalExceedsBalance, fee: 6)), equals: 6)
    }

    @Test("Fee presentation shows failure for staking / network / init-in-progress")
    func feeFailure() {
        expectFailure(.failure(.staking(.minAmountRequirementError(1, action: .stake))))
        expectFailure(.failure(.network(SampleError.any)))
        expectFailure(.prerequisite(.accountInitialization(.inProgress)))
    }

    @Test("Fee presentation is loading while loading")
    func feeLoading() {
        guard case .loading = StakeFlowState.loading.feePresentation else {
            Issue.record("Expected loading")
            return
        }
    }

    // MARK: - Helpers

    private func ready(fee: Decimal = 1) -> StakeFlowState {
        .ready(.init(amount: 1, fee: fee, isFeeIncluded: false, stakesCount: nil))
    }

    private func approveData() -> ApproveTransactionData {
        ApproveTransactionData(txData: Data(), spender: "0x", toContractAddress: "0x")
    }

    private func fee(_ value: Decimal) -> Fee {
        Fee(Amount(with: .solana(curve: .ed25519, testnet: false), type: .coin, value: value))
    }

    private func expectFee(_ state: StakeFlowState, equals expected: Decimal) {
        guard case .value(let value) = state.feePresentation else {
            Issue.record("Expected fee value, got \(state.feePresentation)")
            return
        }
        #expect(value == expected)
    }

    private func expectFailure(_ state: StakeFlowState) {
        guard case .failure = state.feePresentation else {
            Issue.record("Expected failure")
            return
        }
    }

    private enum SampleError: Error { case any }
}
