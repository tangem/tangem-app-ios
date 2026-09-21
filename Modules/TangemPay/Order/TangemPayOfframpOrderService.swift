//
//  TangemPayOfframpOrderService.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol TangemPayOfframpOrderService {
    func placeOrder(
        request: TangemPayPlaceOrderRequest,
        idempotencyKey: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse

    func getOrder(id: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse

    func sendSignature(
        orderId: String,
        signature: String,
        idempotencyKey: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse

    func cancelOrder(id: String) async throws(TangemPayAPIServiceError) -> TangemPayCancelOrderResponse
}

public struct CommonTangemPayOfframpOrderService {
    private let customerService: any CustomerInfoManagementService

    public init(customerService: any CustomerInfoManagementService) {
        self.customerService = customerService
    }
}

// MARK: - TangemPayOfframpOrderService

extension CommonTangemPayOfframpOrderService: TangemPayOfframpOrderService {
    public func placeOrder(
        request: TangemPayPlaceOrderRequest,
        idempotencyKey: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
    }

    public func getOrder(id: String) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        try await customerService.getOrder(orderId: id)
    }

    public func sendSignature(
        orderId: String,
        signature: String,
        idempotencyKey: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        try await customerService.sendBankOfframpSignature(
            orderId: orderId,
            signature: signature,
            idempotencyKey: idempotencyKey
        )
    }

    public func cancelOrder(id: String) async throws(TangemPayAPIServiceError) -> TangemPayCancelOrderResponse {
        try await customerService.cancelOrder(orderId: id)
    }
}
