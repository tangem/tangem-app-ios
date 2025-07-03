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

class CommonAllowanceService {
    private let tokenItem: TokenItem
    private let allowanceChecker: AllowanceChecker

    private var spendersAwaitingApprove: Set<String> = []

    init(tokenItem: TokenItem, allowanceChecker: AllowanceChecker) {
        self.tokenItem = tokenItem
        self.allowanceChecker = allowanceChecker
    }
}

// MARK: - AllowanceService

extension CommonAllowanceService: AllowanceService {
    var isSupportAllowance: Bool {
        tokenItem.blockchain.isEvm && tokenItem.isToken
    }

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

    func didSendApproveTransaction(for spender: String) {
        spendersAwaitingApprove.insert(spender)
    }
}
