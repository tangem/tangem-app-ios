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
        let result = try await allowanceChecker.allowanceState(amount: amount, spender: spender, policy: approvePolicy)

        switch result {
        case .enoughAllowance:
            spendersAwaitingApprove.remove(spender)
            return .enoughAllowance

        case .approveRequired(let data):
            if spendersAwaitingApprove.contains(spender) {
                return .approveTransactionInProgress
            }
            return .permissionRequired(data)

        case .revokeAndApproveRequired(let revoke, let approve):
            if spendersAwaitingApprove.contains(spender) {
                return .approveTransactionInProgress
            }
            ExpressLogger.info("Revoke+approve required for spender: \(spender)")
            return .revokeAndPermissionRequired(revoke: revoke, approve: approve)
        }
    }

    func markApproveTransactionSent(spender: String) {
        spendersAwaitingApprove.insert(spender)
    }
}
