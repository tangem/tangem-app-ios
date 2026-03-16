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
    private var spendersAwaitingApprove: Set<String> = []

    init(allowanceChecker: AllowanceChecker) {
        self.allowanceChecker = allowanceChecker
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

        if spendersAwaitingApprove.contains(spender) {
            return .approveTransactionInProgress
        }

        let approveData = try allowanceChecker.makeApproveData(spender: spender, amount: amount, policy: approvePolicy)
        return .permissionRequired(approveData)
    }

    func markApproveTransactionSent(spender: String) {
        spendersAwaitingApprove.insert(spender)
    }
}
