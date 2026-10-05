//
//  AllowanceServiceMock.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Foundation
import BlockchainSdk
import TangemFoundation
@testable import Tangem

final class AllowanceServiceMock: AllowanceService {
    var supportsOneTapApprove: Bool = true

    private struct State {
        var allowanceStateResult: Result<AllowanceState, Error> = .success(.enoughAllowance)
        var markApproveTransactionSentCalls: [String] = []
        var makeApproveDataResult: Result<ApproveTransactionData, Error>?
        var makeApproveDataResultsByPolicy: [ApprovePolicy: Result<ApproveTransactionData, Error>] = [:]
        var makeApproveDataCalls: [(spender: String, amount: Decimal, policy: ApprovePolicy)] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    // MARK: - Stubs

    var allowanceStateResult: Result<AllowanceState, Error> {
        get { state { $0.allowanceStateResult } }
        set { state { $0.allowanceStateResult = newValue } }
    }

    var makeApproveDataResult: Result<ApproveTransactionData, Error>? {
        get { state { $0.makeApproveDataResult } }
        set { state { $0.makeApproveDataResult = newValue } }
    }

    func setMakeApproveDataResult(_ result: Result<ApproveTransactionData, Error>, for policy: ApprovePolicy) {
        state { $0.makeApproveDataResultsByPolicy[policy] = result }
    }

    var makeApproveDataGate: TestGate?

    // MARK: - Call tracking

    var markApproveTransactionSentCalls: [String] {
        state { $0.markApproveTransactionSentCalls }
    }

    var makeApproveDataCalls: [(spender: String, amount: Decimal, policy: ApprovePolicy)] {
        state { $0.makeApproveDataCalls }
    }

    // MARK: - AllowanceService

    func allowanceState(amount: Decimal, spender: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState {
        try allowanceStateResult.get()
    }

    func markApproveTransactionSent(spender: String) async {
        state { $0.markApproveTransactionSentCalls.append(spender) }
    }

    func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) async throws -> ApproveTransactionData {
        state { $0.makeApproveDataCalls.append((spender, amount, policy)) }

        await makeApproveDataGate?.wait()

        let result = state { $0.makeApproveDataResultsByPolicy[policy] ?? $0.makeApproveDataResult }

        guard let result else {
            return ApproveTransactionData(txData: Data(), spender: spender, toContractAddress: "")
        }

        return try result.get()
    }
}
