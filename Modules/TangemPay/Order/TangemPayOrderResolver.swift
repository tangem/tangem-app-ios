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

    /// Returns the most recent active order matching `predicate`, or `nil` if none exists.
    public func findActiveOrder(
        types: [String],
        matching predicate: (TangemPayOrderResponse) -> Bool
    ) async throws -> TangemPayOrderResponse? {
        let orders = try await customerService.findOrders(types: types, statuses: [.new, .processing])
        return orders.filter(predicate).mostRecentByUpdatedAt
    }

    /// Places an order, translating the `cardIssueInsufficientBalance` API error into the
    /// resolver's typed `.insufficientBalance` so callers (specifically the additional-card-issue
    /// flow per FR-MOB-BR6-006) can render the dedicated insufficient-funds UI without reaching
    /// into BFF error codes.
    public func placeOrder(
        request: TangemPayPlaceOrderRequest,
        idempotencyKey: String
    ) async throws -> TangemPayOrderResponse {
        do {
            return try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
        } catch let serviceError as TangemPayAPIServiceError {
            if case .apiError(let apiError) = serviceError,
               apiError.code == TangemPayAPIError.Code.cardIssueInsufficientBalance {
                throw TangemPayOrderResolverError.insufficientBalance
            }
            throw serviceError
        }
    }
}

public enum TangemPayOrderResolverError: Error {
    case insufficientBalance
}

public extension Sequence where Element == TangemPayOrderResponse {
    /// FR-MOB-ORDER-002: deterministic selection rule for picking one out of several active
    /// orders — most recent by `updatedAt`.
    var mostRecentByUpdatedAt: TangemPayOrderResponse? {
        self.max { lhs, rhs in
            (lhs.updatedAt ?? .distantPast) < (rhs.updatedAt ?? .distantPast)
        }
    }
}
