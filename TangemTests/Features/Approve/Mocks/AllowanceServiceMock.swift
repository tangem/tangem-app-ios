//
//  AllowanceServiceMock.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Combine
import BlockchainSdk
@testable import Tangem

final class AllowanceServiceMock: AllowanceService {
    // MARK: - Stubs

    var allowanceStateResult: Result<AllowanceState, Error> = .success(.enoughAllowance)

    // MARK: - Call tracking

    private(set) var allowanceStateCalls: [(amount: Decimal, spender: String, approvePolicy: ApprovePolicy)] = []
    private(set) var markApproveTransactionSentCalls: [String] = []

    // MARK: - AllowanceService

    func allowanceState(amount: Decimal, spender: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState {
        allowanceStateCalls.append((amount, spender, approvePolicy))
        return try allowanceStateResult.get()
    }

    func markApproveTransactionSent(spender: String) async {
        markApproveTransactionSentCalls.append(spender)
    }
}
