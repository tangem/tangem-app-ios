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

    public func findActiveOrder(
        types: [String],
        matching predicate: (TangemPayOrderResponse) -> Bool
    ) async throws -> TangemPayOrderResponse? {
        let orders = try await customerService.findOrders(types: types, statuses: [.new, .processing])
        return orders.filter(predicate).mostRecentByUpdatedAt
    }

    public func placeOrder(
        request: TangemPayPlaceOrderRequest,
        idempotencyKey: String
    ) async throws -> TangemPayOrderResponse {
        do {
            return try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
        } catch let serviceError {
            if case .apiError(let apiError) = serviceError,
               apiError.code == TangemPayAPIError.Code.cardIssueInsufficientBalance {
                throw TangemPayOrderResolverError.insufficientBalance
            }
            throw serviceError
        }
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
        ), let existing = orders.first(where: { order in
            order.type == orderType
                && order.data?.specificationName == specificationName
                && order.data?.customerWalletAddress == customerWalletAddress
        }) {
            return existing
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

public extension Sequence where Element == TangemPayOrderResponse {
    var mostRecentByUpdatedAt: TangemPayOrderResponse? {
        self.max { lhs, rhs in
            (lhs.updatedAt ?? .distantPast) < (rhs.updatedAt ?? .distantPast)
        }
    }
}
