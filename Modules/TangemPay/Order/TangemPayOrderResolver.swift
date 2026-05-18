//
//  TangemPayOrderResolver.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayOrderResolver {
    private let customerService: any CustomerInfoManagementService

    public init(customerService: any CustomerInfoManagementService) {
        self.customerService = customerService
    }

    public func resolveOrCreateAdditionalCardIssueOrder(
        orderType: String,
        customerWalletAddress: String,
        specificationName: String,
        idempotencyKey: String
    ) async throws -> TangemPayOrderResponse {
        // Errors here are swallowed: a fresh placement is safe because the idempotency key prevents
        // server-side duplicates.
        if let orders = try? await customerService.findOrders(
            types: TangemPayOrderType.cardIssueFamily,
            statuses: [.new, .processing]
        ) {
            let candidates = orders.filter { order in
                order.type == orderType
                    && order.data?.specificationName == specificationName
                    && order.data?.customerWalletAddress == customerWalletAddress
            }
            let sorted = candidates.sorted { lhs, rhs in
                (lhs.updatedAt ?? .distantPast) > (rhs.updatedAt ?? .distantPast)
            }
            if let existing = sorted.first {
                return existing
            }
        }

        let request = TangemPayPlaceOrderRequest(
            type: orderType,
            customerWalletAddress: customerWalletAddress,
            specificationName: specificationName
        )

        do {
            return try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
        } catch {
            // BFF code 140116 = CardIssueInsufficientBalanceException
            if case .apiError(let apiError) = error, apiError.code == 140116 {
                throw TangemPayOrderResolverError.insufficientBalance
            }
            throw error
        }
    }
}

public enum TangemPayOrderResolverError: Error {
    case insufficientBalance
}
