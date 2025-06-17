//
//  CommonAllowanceProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

// Convenient aliases. Move it to BSDK
// [REDACTED_TODO_COMMENT]
typealias AllowanceState = TangemExpress.AllowanceState
typealias ApprovePolicy = TangemExpress.ExpressApprovePolicy
typealias ApproveTransactionData = TangemExpress.ApproveTransactionData
typealias AllowanceProvider = TangemExpress.AllowanceProvider

class CommonAllowanceProvider {
    private var walletModel: any WalletModel
    private var spendersAwaitingApprove: Set<String> = []

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }
}

// MARK: - AllowanceProvider

extension CommonAllowanceProvider: AllowanceProvider {
    var isSupportAllowance: Bool {
        walletModel.tokenItem.blockchain.isEvm && walletModel.tokenItem.isToken
    }

    func allowanceState(amount: Decimal, spender: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState {
        let checker = AllowanceChecker(walletModel: walletModel)
        let isPermissionRequired = try await checker.isPermissionRequired(amount: amount, spender: spender)

        guard isPermissionRequired else {
            spendersAwaitingApprove.remove(spender)

            return .enoughAllowance
        }

        let approveTxWasSent = spendersAwaitingApprove.contains(spender)
        if approveTxWasSent {
            return .approveTransactionInProgress
        }

        let approveData = try await checker.makeApproveData(spender: spender, amount: amount, policy: approvePolicy)
        return .permissionRequired(approveData)
    }

    func didSendApproveTransaction(for spender: String) {
        spendersAwaitingApprove.insert(spender)
    }
}

// MARK: - UpdatableAllowanceProvider

extension CommonAllowanceProvider: UpdatableAllowanceProvider {
    func setup(wallet: any WalletModel) {
        walletModel = wallet
    }
}
