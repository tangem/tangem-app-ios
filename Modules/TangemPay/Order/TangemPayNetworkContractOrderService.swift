//
//  TangemPayNetworkContractOrderService.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class TangemPayNetworkContractOrderService {
    private let customerService: any CustomerInfoManagementService
    private let orderResolver: TangemPayOrderResolver
    private let pollingService: TangemPayOrderStatusPollingService

    private var orderTask: Task<Void, Never>?

    public init(customerService: any CustomerInfoManagementService) {
        self.customerService = customerService
        orderResolver = TangemPayOrderResolver(customerService: customerService)
        pollingService = TangemPayOrderStatusPollingService(customerService: customerService)
    }

    public func start(
        chainId: Int,
        onResult: @escaping (Result) -> Void
    ) {
        cancel()

        orderTask = runTask(in: self) { service in
            await service.issueContract(
                chainId: chainId,
                onResult: onResult
            )
        }
    }

    public func cancel() {
        orderTask?.cancel()
        pollingService.cancel()
    }

    deinit {
        cancel()
    }
}

// MARK: - Nested types

public extension TangemPayNetworkContractOrderService {
    enum Result {
        case completed(depositAddress: String?)
        case canceled
        case timedOut
        case failed(Error)
    }
}

// MARK: - Private

private extension TangemPayNetworkContractOrderService {
    func issueContract(
        chainId: Int,
        onResult: @escaping (Result) -> Void
    ) async {
        if let activeOrder = await findActiveOrder(chainId: chainId) {
            startPolling(orderId: activeOrder.id, chainId: chainId, onResult: onResult)
            return
        }

        do {
            let placedOrder = try await placeOrder(chainId: chainId)
            startPolling(orderId: placedOrder.id, chainId: chainId, onResult: onResult)
        } catch {
            onResult(.failed(error))
        }
    }

    func findActiveOrder(chainId: Int) async -> TangemPayOrderResponse? {
        if let order = try? await orderResolver.findActiveNetworkContractOrder(chainId: chainId) {
            return order
        }

        return try? await orderResolver.findActiveNetworkContractOrder(chainId: chainId)
    }

    func placeOrder(chainId: Int) async throws(TangemPayAPIServiceError) -> TangemPayOrderResponse {
        let request = TangemPayPlaceOrderRequest(networkContractChainId: chainId)
        let idempotencyKey = UUID().uuidString

        for delay in TangemPayNetworkContractOrderRetryPolicy.placeOrderDelays {
            do {
                return try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
            } catch {
                guard TangemPayNetworkContractOrderRetryPolicy.isRetryable(error) else {
                    throw error
                }

                try? await Task.sleep(for: .seconds(delay))

                guard !Task.isCancelled else {
                    throw error
                }
            }
        }

        return try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
    }

    func startPolling(orderId: String, chainId: Int, onResult: @escaping (Result) -> Void) {
        pollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.pollInterval,
            onCompleted: { [weak self] in
                self?.readDepositAddress(orderId: orderId, chainId: chainId, onResult: onResult)
            },
            onCanceled: {
                onResult(.canceled)
            },
            onFailed: { error in
                onResult(.failed(error))
            },
            timeout: Constants.pollTimeout,
            onTimeout: {
                onResult(.timedOut)
            }
        )
    }

    func readDepositAddress(orderId: String, chainId: Int, onResult: @escaping (Result) -> Void) {
        runTask(in: self) { service in
            let order = try? await service.customerService.getOrder(orderId: orderId)
            let data = order?.data

            onResult(.completed(depositAddress: data?.chainId == chainId ? data?.depositAddress : nil))
        }
    }

    enum Constants {
        static let pollInterval: TimeInterval = 3
        static let pollTimeout: TimeInterval = 60
    }
}
