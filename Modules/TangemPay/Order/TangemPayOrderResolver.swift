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

    public func findActiveCardIssueOrder() async throws -> TangemPayOrderResponse? {
        let orders = try await customerService.findOrders(
            types: TangemPayOrderType.cardIssueFamily,
            statuses: [.new, .processing]
        )
        return orders.mostRecentByUpdatedAt
    }

    public func findActiveTariffPlanTransitionOrder() async throws -> TangemPayOrderResponse? {
        let orders = try await customerService.findOrders(
            types: TangemPayOrderType.tariffPlanTransitionFamily,
            statuses: [.new, .processing]
        )
        return orders.mostRecentByUpdatedAt
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
