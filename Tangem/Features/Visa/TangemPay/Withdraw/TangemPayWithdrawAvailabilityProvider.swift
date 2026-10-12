//
//  TangemPayWithdrawAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay

struct TangemPayWithdrawAvailabilityProvider {
    private let withdrawTransactionService: any TangemPayWithdrawTransactionService
    private let orderResolver: TangemPayOrderResolver
    private let tokenBalanceProvider: any TokenBalanceProvider

    init(
        withdrawTransactionService: any TangemPayWithdrawTransactionService,
        orderResolver: TangemPayOrderResolver,
        tokenBalanceProvider: any TokenBalanceProvider
    ) {
        self.withdrawTransactionService = withdrawTransactionService
        self.orderResolver = orderResolver
        self.tokenBalanceProvider = tokenBalanceProvider
    }

    func restriction() async throws -> SendingRestrictions? {
        async let withdrawOrderRequest = withdrawTransactionService.hasActiveWithdrawOrder()
        async let bankOfframpOrderRequest = orderResolver.findActiveBankOfframpOrder()

        let hasActiveWithdrawOrder = try await withdrawOrderRequest
        let activeBankOfframpOrder = try await bankOfframpOrderRequest

        if hasActiveWithdrawOrder || activeBankOfframpOrder != nil {
            return .hasPendingWithdrawOrder
        }

        if let sendingRestrictions = tokenBalanceProvider.balanceType.sendingRestrictions {
            return sendingRestrictions
        }

        return .none
    }
}
