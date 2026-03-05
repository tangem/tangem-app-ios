//
//  CommonAllowanceService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

actor CommonAllowanceService {
    private let allowanceChecker: AllowanceChecker
    private let approveTransactionDispatcher: any TransactionDispatcher

    private var spendersAwaitingApprove: Set<String> = []

    init(
        allowanceChecker: AllowanceChecker,
        approveTransactionDispatcher: any TransactionDispatcher,
    ) {
        self.allowanceChecker = allowanceChecker
        self.approveTransactionDispatcher = approveTransactionDispatcher
    }
}

// MARK: - AllowanceService

extension CommonAllowanceService: AllowanceService {
    func allowanceState(amount: Decimal, spender: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState {
        let isPermissionRequired = try await allowanceChecker.isPermissionRequired(amount: amount, spender: spender)

        guard isPermissionRequired else {
            spendersAwaitingApprove.remove(spender)
            return .enoughAllowance
        }

        let approveTxWasSent = spendersAwaitingApprove.contains(spender)
        if approveTxWasSent {
            return .approveTransactionInProgress
        }

        let approveData = try await allowanceChecker.makeApproveData(spender: spender, amount: amount, policy: approvePolicy)
        return .permissionRequired(approveData)
    }

    func sendApproveTransaction(data: ApproveTransactionData) async throws -> TransactionDispatcherResult {
        let result = try await approveTransactionDispatcher.send(transaction: .approve(data: data))
        spendersAwaitingApprove.insert(data.spender)

        return result
    }
}
