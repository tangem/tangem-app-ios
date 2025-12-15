//
//  TangemPayWithdrawAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayWithdrawAvailabilityProvider {
    private let withdrawTransactionService: any TangemPayWithdrawTransactionService
    private let tokenBalanceProvider: any TokenBalanceProvider

    init(
        withdrawTransactionService: any TangemPayWithdrawTransactionService,
        tokenBalanceProvider: any TokenBalanceProvider
    ) {
        self.withdrawTransactionService = withdrawTransactionService
        self.tokenBalanceProvider = tokenBalanceProvider
    }

    func restriction() async throws -> SendingRestrictions? {
        let hasActiveWithdrawOrder = try await withdrawTransactionService.hasActiveWithdrawOrder()

        if hasActiveWithdrawOrder {
            return .hasPendingWithdrawOrder
        }

        if let sendingRestrictions = tokenBalanceProvider.balanceType.sendingRestrictions {
            return sendingRestrictions
        }

        return .none
    }
}
